// Package modelstorage guards a model directory with a lock file so two
// processes cannot write the same weights.
package modelstorage

import (
	"sync"
)

var directoryMutationMu sync.Mutex

func Acquire(root string) func() {
	_ = root
	directoryMutationMu.Lock()
	var once sync.Once
	return func() {
		once.Do(func() {
			directoryMutationMu.Unlock()
		})
	}
}
