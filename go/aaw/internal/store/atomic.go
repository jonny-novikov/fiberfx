package store

import (
	"os"
	"path/filepath"
)

// writeFileAtomic replaces path with data via temp + fsync + rename in the
// target directory, so a reader observes either the complete prior file or
// the complete new file, never a torn one (MCP1-D3 / ADR-4). Line-granular
// logs (messages.jsonl, audit.log — later rungs) use O_APPEND, not this.
func writeFileAtomic(path string, data []byte, perm os.FileMode) error {
	f, err := os.CreateTemp(filepath.Dir(path), filepath.Base(path)+".tmp.*")
	if err != nil {
		return err
	}
	tmp := f.Name()
	if _, err := f.Write(data); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Chmod(perm); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Sync(); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(tmp)
		return err
	}
	if err := os.Rename(tmp, path); err != nil {
		os.Remove(tmp)
		return err
	}
	return nil
}
