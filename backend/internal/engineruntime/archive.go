package engineruntime

import (
	"archive/tar"
	"archive/zip"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// maxExtractedBytes caps what one archive may write. The largest catalogued
// build unpacks to well under this; the limit exists so a malformed or hostile
// archive cannot fill the disk.
const maxExtractedBytes int64 = 8 << 30

// extractArchive unpacks a downloaded release archive into destination, which
// must already exist. Entries are confined to destination: absolute paths,
// parent traversal and symlinks pointing outside are all refused rather than
// sanitised, because a release archive has no legitimate reason to contain them.
func extractArchive(archivePath, destination string) error {
	absoluteDestination, err := filepath.Abs(destination)
	if err != nil {
		return err
	}
	switch {
	case strings.HasSuffix(archivePath, ".zip"):
		return extractZip(archivePath, absoluteDestination)
	case strings.HasSuffix(archivePath, ".tar.gz"):
		return extractTarGz(archivePath, absoluteDestination)
	default:
		return fmt.Errorf("unsupported archive format for %s", filepath.Base(archivePath))
	}
}

// resolveEntryPath maps an archive entry name onto a path inside destination,
// refusing anything that would land outside it.
func resolveEntryPath(destination, name string) (string, error) {
	if name == "" {
		return "", errors.New("archive entry has an empty name")
	}
	// Archive names are always slash-separated, whatever the host separator is.
	cleaned := filepath.Clean(filepath.FromSlash(name))
	if filepath.IsAbs(cleaned) || strings.HasPrefix(cleaned, string(filepath.Separator)) {
		return "", fmt.Errorf("archive entry %q is an absolute path", name)
	}
	if volume := filepath.VolumeName(cleaned); volume != "" {
		return "", fmt.Errorf("archive entry %q names a volume", name)
	}
	target := filepath.Join(destination, cleaned)
	if target != destination && !strings.HasPrefix(target, destination+string(filepath.Separator)) {
		return "", fmt.Errorf("archive entry %q escapes the install directory", name)
	}
	return target, nil
}

// resolveLinkTarget validates a symlink before it is created. Relative targets
// are resolved against the link's own directory; absolute targets are refused.
func resolveLinkTarget(destination, linkPath, linkTarget string) error {
	if linkTarget == "" {
		return errors.New("archive entry has an empty link target")
	}
	cleaned := filepath.FromSlash(linkTarget)
	if filepath.IsAbs(cleaned) || filepath.VolumeName(cleaned) != "" {
		return fmt.Errorf("symlink %q points at an absolute path", linkPath)
	}
	resolved := filepath.Clean(filepath.Join(filepath.Dir(linkPath), cleaned))
	if resolved != destination && !strings.HasPrefix(resolved, destination+string(filepath.Separator)) {
		return fmt.Errorf("symlink %q points outside the install directory", linkPath)
	}
	return nil
}

// entryMode keeps the execute bit an archive recorded but never grants group or
// world write access.
func entryMode(mode os.FileMode) os.FileMode {
	if mode&0o111 != 0 {
		return 0o755
	}
	return 0o644
}

func extractZip(archivePath, destination string) error {
	reader, err := zip.OpenReader(archivePath)
	if err != nil {
		return fmt.Errorf("open %s: %w", filepath.Base(archivePath), err)
	}
	defer reader.Close()

	var written int64
	for _, entry := range reader.File {
		target, err := resolveEntryPath(destination, entry.Name)
		if err != nil {
			return err
		}
		info := entry.FileInfo()
		switch {
		case info.IsDir():
			if err := os.MkdirAll(target, 0o755); err != nil {
				return err
			}
		case info.Mode()&os.ModeSymlink != 0:
			linkTarget, err := readZipSymlink(entry)
			if err != nil {
				return err
			}
			if err := resolveLinkTarget(destination, target, linkTarget); err != nil {
				return err
			}
			if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
				return err
			}
			if err := os.Symlink(linkTarget, target); err != nil {
				return err
			}
		case info.Mode().IsRegular():
			written, err = copyZipFile(entry, target, info.Mode(), written)
			if err != nil {
				return err
			}
		default:
			// Sockets, devices and pipes have no place in a release archive.
			continue
		}
	}
	return nil
}

func readZipSymlink(entry *zip.File) (string, error) {
	handle, err := entry.Open()
	if err != nil {
		return "", err
	}
	defer handle.Close()
	// A symlink's body is its target path; cap the read so a mislabelled entry
	// cannot pull an arbitrary amount into memory.
	value, err := io.ReadAll(io.LimitReader(handle, 4096))
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(value)), nil
}

func copyZipFile(entry *zip.File, target string, mode os.FileMode, written int64) (int64, error) {
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		return written, err
	}
	source, err := entry.Open()
	if err != nil {
		return written, err
	}
	defer source.Close()
	return copyEntry(source, target, entryMode(mode), written)
}

func extractTarGz(archivePath, destination string) error {
	handle, err := os.Open(archivePath)
	if err != nil {
		return fmt.Errorf("open %s: %w", filepath.Base(archivePath), err)
	}
	defer handle.Close()
	decompressor, err := gzip.NewReader(handle)
	if err != nil {
		return fmt.Errorf("read %s: %w", filepath.Base(archivePath), err)
	}
	defer decompressor.Close()

	var written int64
	reader := tar.NewReader(decompressor)
	for {
		header, err := reader.Next()
		if errors.Is(err, io.EOF) {
			return nil
		}
		if err != nil {
			return fmt.Errorf("read %s: %w", filepath.Base(archivePath), err)
		}
		target, err := resolveEntryPath(destination, header.Name)
		if err != nil {
			return err
		}
		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(target, 0o755); err != nil {
				return err
			}
		case tar.TypeSymlink:
			// The llama.cpp tarballs rely on relative symlinks for their shared
			// library sonames, so these have to survive extraction intact.
			if err := resolveLinkTarget(destination, target, header.Linkname); err != nil {
				return err
			}
			if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
				return err
			}
			if err := os.Symlink(header.Linkname, target); err != nil {
				return err
			}
		case tar.TypeLink:
			linkTarget, err := resolveEntryPath(destination, header.Linkname)
			if err != nil {
				return err
			}
			if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
				return err
			}
			if err := os.Link(linkTarget, target); err != nil {
				return err
			}
		case tar.TypeReg:
			written, err = copyEntry(reader, target, entryMode(header.FileInfo().Mode()), written)
			if err != nil {
				return err
			}
		default:
			continue
		}
	}
}

func copyEntry(source io.Reader, target string, mode os.FileMode, written int64) (int64, error) {
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		return written, err
	}
	file, err := os.OpenFile(target, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, mode)
	if err != nil {
		return written, err
	}
	defer file.Close()
	remaining := maxExtractedBytes - written
	if remaining <= 0 {
		return written, fmt.Errorf("archive expands beyond the %d byte extraction limit", maxExtractedBytes)
	}
	copied, err := io.Copy(file, io.LimitReader(source, remaining+1))
	written += copied
	if err != nil {
		return written, err
	}
	if copied > remaining {
		return written, fmt.Errorf("archive expands beyond the %d byte extraction limit", maxExtractedBytes)
	}
	if err := file.Close(); err != nil {
		return written, err
	}
	// OpenFile honours the umask, so set the mode explicitly to keep the
	// execute bit the archive recorded.
	return written, os.Chmod(target, mode)
}

// findServerBinary locates llama-server inside an unpacked build. Archive
// layouts differ between platforms (a top-level directory on Linux and macOS,
// files at the root on Windows), so the binary is searched for rather than
// assumed. The returned path is relative to root.
func findServerBinary(root string) (string, error) {
	wanted := ServerBinaryName()
	var found string
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if found != "" {
			return filepath.SkipAll
		}
		if entry.IsDir() || entry.Name() != wanted {
			return nil
		}
		info, infoErr := entry.Info()
		if infoErr != nil || !info.Mode().IsRegular() {
			return nil
		}
		found = path
		return filepath.SkipAll
	})
	if err != nil {
		return "", err
	}
	if found == "" {
		return "", fmt.Errorf("%s was not found in the unpacked build", wanted)
	}
	relative, err := filepath.Rel(root, found)
	if err != nil {
		return "", err
	}
	return relative, nil
}
