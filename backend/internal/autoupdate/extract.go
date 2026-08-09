package autoupdate

import (
	"archive/tar"
	"archive/zip"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"
)

const (
	maxArchiveFiles             = 100_000
	maxArchiveUncompressedBytes = int64(16 << 30)
	maxSymlinkTargetBytes       = int64(4 << 10)
)

type pendingSymlink struct {
	path   string
	target string
}

type archiveExtractor struct {
	destination string
	seen        map[string]fs.FileMode
	files       int
	bytes       int64
	symlinks    []pendingSymlink
}

func ExtractArchive(archivePath, format, destination string) error {
	if err := os.MkdirAll(destination, 0o700); err != nil {
		return fmt.Errorf("create update staging directory: %w", err)
	}
	extractor := &archiveExtractor{
		destination: destination,
		seen:        make(map[string]fs.FileMode),
	}
	var err error
	switch format {
	case "zip":
		err = extractor.extractZip(archivePath)
	case "tar.gz":
		err = extractor.extractTarGzip(archivePath)
	default:
		err = fmt.Errorf("unsupported archive format %q", format)
	}
	if err != nil {
		return err
	}
	if err := extractor.createSymlinks(); err != nil {
		return err
	}
	return nil
}

func (extractor *archiveExtractor) extractZip(archivePath string) error {
	reader, err := zip.OpenReader(archivePath)
	if err != nil {
		return fmt.Errorf("open ZIP update: %w", err)
	}
	defer reader.Close()
	for _, entry := range reader.File {
		clean, err := extractor.admit(entry.Name, entry.Mode(), int64(entry.UncompressedSize64))
		if err != nil {
			return err
		}
		if entry.FileInfo().IsDir() {
			if err := extractor.createDirectory(clean, entry.Mode()); err != nil {
				return err
			}
			continue
		}
		input, err := entry.Open()
		if err != nil {
			return fmt.Errorf("open ZIP entry %q: %w", entry.Name, err)
		}
		if entry.Mode()&os.ModeSymlink != 0 {
			target, readErr := readSymlinkTarget(input)
			closeErr := input.Close()
			if readErr != nil {
				return fmt.Errorf("read ZIP symlink %q: %w", entry.Name, readErr)
			}
			if closeErr != nil {
				return fmt.Errorf("close ZIP symlink %q: %w", entry.Name, closeErr)
			}
			if err := extractor.addSymlink(clean, target); err != nil {
				return err
			}
			continue
		}
		if !entry.Mode().IsRegular() {
			input.Close()
			return fmt.Errorf("ZIP entry %q has unsupported type %s", entry.Name, entry.Mode().Type())
		}
		writeErr := extractor.writeFile(clean, entry.Mode(), input, int64(entry.UncompressedSize64))
		closeErr := input.Close()
		if writeErr != nil {
			return writeErr
		}
		if closeErr != nil {
			return fmt.Errorf("close ZIP entry %q: %w", entry.Name, closeErr)
		}
	}
	return nil
}

func (extractor *archiveExtractor) extractTarGzip(archivePath string) error {
	file, err := os.Open(archivePath)
	if err != nil {
		return fmt.Errorf("open tar.gz update: %w", err)
	}
	defer file.Close()
	gzipReader, err := gzip.NewReader(file)
	if err != nil {
		return fmt.Errorf("open gzip update: %w", err)
	}
	defer gzipReader.Close()
	reader := tar.NewReader(gzipReader)
	for {
		header, err := reader.Next()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return fmt.Errorf("read tar.gz update: %w", err)
		}
		mode := header.FileInfo().Mode()
		clean, err := extractor.admit(header.Name, mode, header.Size)
		if err != nil {
			return err
		}
		switch header.Typeflag {
		case tar.TypeDir:
			if err := extractor.createDirectory(clean, mode); err != nil {
				return err
			}
		case tar.TypeReg, tar.TypeRegA:
			if err := extractor.writeFile(clean, mode, reader, header.Size); err != nil {
				return err
			}
		case tar.TypeSymlink:
			if err := extractor.addSymlink(clean, header.Linkname); err != nil {
				return err
			}
		default:
			return fmt.Errorf("tar entry %q has unsupported type %d", header.Name, header.Typeflag)
		}
	}
	return nil
}

func (extractor *archiveExtractor) admit(raw string, mode fs.FileMode, size int64) (string, error) {
	clean, err := safeArchivePath(raw)
	if err != nil {
		return "", fmt.Errorf("unsafe archive entry: %w", err)
	}
	if previous, exists := extractor.seen[clean]; exists {
		if previous.IsDir() && mode.IsDir() {
			return clean, nil
		}
		return "", fmt.Errorf("archive contains duplicate entry %q", clean)
	}
	extractor.seen[clean] = mode
	extractor.files++
	if extractor.files > maxArchiveFiles {
		return "", fmt.Errorf("archive contains more than %d entries", maxArchiveFiles)
	}
	if size < 0 || extractor.bytes > maxArchiveUncompressedBytes-size {
		return "", fmt.Errorf("archive expands beyond %d bytes", maxArchiveUncompressedBytes)
	}
	extractor.bytes += size
	return clean, nil
}

func (extractor *archiveExtractor) createDirectory(relative string, mode fs.FileMode) error {
	destination := filepath.Join(extractor.destination, filepath.FromSlash(relative))
	permissions := sanitizedPermissions(mode, true)
	if err := os.MkdirAll(destination, permissions); err != nil {
		return fmt.Errorf("create archive directory %q: %w", relative, err)
	}
	return nil
}

func (extractor *archiveExtractor) writeFile(relative string, mode fs.FileMode, input io.Reader, expected int64) (err error) {
	destination := filepath.Join(extractor.destination, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
		return fmt.Errorf("create parent for archive entry %q: %w", relative, err)
	}
	output, err := os.OpenFile(destination, os.O_CREATE|os.O_EXCL|os.O_WRONLY, sanitizedPermissions(mode, false))
	if err != nil {
		return fmt.Errorf("create archive entry %q: %w", relative, err)
	}
	keep := false
	defer func() {
		_ = output.Close()
		if !keep {
			_ = os.Remove(destination)
		}
	}()
	written, err := io.Copy(output, io.LimitReader(input, expected+1))
	if err != nil {
		return fmt.Errorf("write archive entry %q: %w", relative, err)
	}
	if written != expected {
		return fmt.Errorf("archive entry %q has %d bytes, expected %d", relative, written, expected)
	}
	if err := output.Close(); err != nil {
		return fmt.Errorf("close archive entry %q: %w", relative, err)
	}
	keep = true
	return nil
}

func (extractor *archiveExtractor) addSymlink(relative, rawTarget string) error {
	if strings.IndexByte(rawTarget, 0) >= 0 || rawTarget == "" {
		return fmt.Errorf("symlink %q has an empty or invalid target", relative)
	}
	normalizedTarget := strings.ReplaceAll(rawTarget, "\\", "/")
	if strings.HasPrefix(normalizedTarget, "/") ||
		(len(normalizedTarget) >= 2 && normalizedTarget[1] == ':') {
		return fmt.Errorf("symlink %q has an absolute target", relative)
	}
	resolved := path.Clean(path.Join(path.Dir(relative), normalizedTarget))
	if resolved == ".." || strings.HasPrefix(resolved, "../") {
		return fmt.Errorf("symlink %q escapes the bundle", relative)
	}
	if resolved == relative {
		return fmt.Errorf("symlink %q points to itself", relative)
	}
	extractor.symlinks = append(extractor.symlinks, pendingSymlink{
		path:   relative,
		target: normalizedTarget,
	})
	return nil
}

func (extractor *archiveExtractor) createSymlinks() error {
	sort.Slice(extractor.symlinks, func(left, right int) bool {
		return strings.Count(extractor.symlinks[left].path, "/") <
			strings.Count(extractor.symlinks[right].path, "/")
	})
	for _, link := range extractor.symlinks {
		destination := filepath.Join(extractor.destination, filepath.FromSlash(link.path))
		if err := ensureNoSymlinkParent(extractor.destination, filepath.Dir(destination)); err != nil {
			return fmt.Errorf("create symlink %q: %w", link.path, err)
		}
		if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
			return fmt.Errorf("create parent for symlink %q: %w", link.path, err)
		}
		if err := os.Symlink(filepath.FromSlash(link.target), destination); err != nil {
			return fmt.Errorf("create symlink %q: %w", link.path, err)
		}
	}
	return nil
}

func ensureNoSymlinkParent(root, directory string) error {
	relative, err := filepath.Rel(root, directory)
	if err != nil {
		return err
	}
	current := root
	for _, component := range strings.Split(relative, string(filepath.Separator)) {
		if component == "" || component == "." {
			continue
		}
		current = filepath.Join(current, component)
		info, err := os.Lstat(current)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return err
		}
		if info.Mode()&os.ModeSymlink != 0 {
			return fmt.Errorf("parent %q is a symlink", current)
		}
	}
	return nil
}

func readSymlinkTarget(reader io.Reader) (string, error) {
	payload, err := io.ReadAll(io.LimitReader(reader, maxSymlinkTargetBytes+1))
	if err != nil {
		return "", err
	}
	if int64(len(payload)) > maxSymlinkTargetBytes {
		return "", fmt.Errorf("target exceeds %d bytes", maxSymlinkTargetBytes)
	}
	return string(payload), nil
}

func sanitizedPermissions(mode fs.FileMode, directory bool) fs.FileMode {
	permissions := mode.Perm() & 0o755
	if directory {
		permissions |= 0o700
		if permissions&0o111 == 0 {
			permissions |= 0o100
		}
		return permissions
	}
	permissions |= 0o600
	return permissions
}
