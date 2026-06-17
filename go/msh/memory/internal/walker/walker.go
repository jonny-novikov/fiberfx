package walker

import (
	"fmt"
	"io/fs"
	"path/filepath"
	"sort"
	"strings"
)

type FileEntry struct {
	AbsPath string
	RelPath string
	Size    int64
}

func WalkMarkdown(root string) ([]FileEntry, error) {
	if root == "" {
		return nil, fmt.Errorf("walker: empty root")
	}
	absRoot, err := filepath.Abs(root)
	if err != nil {
		return nil, fmt.Errorf("walker: resolve root %q: %w", root, err)
	}
	var out []FileEntry
	err = filepath.WalkDir(absRoot, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if d.IsDir() {
			name := d.Name()
			if path != absRoot && strings.HasPrefix(name, ".") {
				return fs.SkipDir
			}
			return nil
		}
		if !strings.EqualFold(filepath.Ext(d.Name()), ".md") {
			return nil
		}
		info, err := d.Info()
		if err != nil {
			return fmt.Errorf("walker: stat %q: %w", path, err)
		}
		rel, err := filepath.Rel(absRoot, path)
		if err != nil {
			return fmt.Errorf("walker: rel %q: %w", path, err)
		}
		out = append(out, FileEntry{
			AbsPath: path,
			RelPath: filepath.ToSlash(rel),
			Size:    info.Size(),
		})
		return nil
	})
	if err != nil {
		return nil, err
	}
	sort.Slice(out, func(i, j int) bool { return out[i].RelPath < out[j].RelPath })
	return out, nil
}
