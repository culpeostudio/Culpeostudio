package modelcatalog

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"hash"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const fingerprintSampleSize int64 = 64 * 1024

// VerifyFingerprint recomputes the sampled fingerprint for the record's files
// and reports whether it still matches the cached record. A mismatch means the
// user replaced, changed, or removed model files after the last scan, so any
// cached metadata (sizes, context limits, memory plans) may be stale.
func VerifyFingerprint(root string, record ModelRecord) bool {
	if strings.TrimSpace(record.Fingerprint) == "" || len(record.Files) == 0 {
		return true
	}
	return sampledFingerprint(root, record.Files) == record.Fingerprint
}

// sampledFingerprint deliberately hashes complete small files and the first
// and last 64 KiB of large weight files. This makes repeated scans practical
// for hundred-gigabyte models while still binding the fingerprint to names,
// exact sizes, headers and trailing tensor data.
func sampledFingerprint(root string, relativeFiles []string) string {
	files := append([]string(nil), relativeFiles...)
	sort.Strings(files)
	h := sha256.New()
	for _, rel := range files {
		writeFingerprintPart(h, []byte(filepath.ToSlash(rel)))
		path := filepath.Join(root, filepath.FromSlash(rel))
		info, err := os.Stat(path)
		if err != nil || !info.Mode().IsRegular() {
			writeFingerprintPart(h, []byte("missing"))
			continue
		}
		var size [8]byte
		binary.LittleEndian.PutUint64(size[:], uint64(info.Size()))
		writeFingerprintPart(h, size[:])
		if err := hashFileSamples(h, path, info.Size()); err != nil {
			writeFingerprintPart(h, []byte(err.Error()))
		}
	}
	return fmt.Sprintf("sha256:%x", h.Sum(nil))
}

func writeFingerprintPart(h hash.Hash, value []byte) {
	var length [8]byte
	binary.LittleEndian.PutUint64(length[:], uint64(len(value)))
	_, _ = h.Write(length[:])
	_, _ = h.Write(value)
}

func hashFileSamples(h hash.Hash, path string, size int64) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()
	if size <= fingerprintSampleSize*2 {
		_, err = io.Copy(h, file)
		return err
	}
	if _, err = io.CopyN(h, file, fingerprintSampleSize); err != nil {
		return err
	}
	if _, err = file.Seek(size-fingerprintSampleSize, io.SeekStart); err != nil {
		return err
	}
	_, err = io.CopyN(h, file, fingerprintSampleSize)
	return err
}
