// Package modelstorage coordinates atomic changes to the shared local model
// directory across the Engine and Marketplace modules.
package modelstorage

import (
	"sync"
)

var directoryMutationMu sync.Mutex

// Acquire serializes destructive/publishing model-directory changes inside
// this process. A single lock is intentional: Marketplace target_dir may be a
// child of the Engine's configured model root, so equality-keyed locks would
// not protect overlapping directory trees. The returned release is idempotent.
func Acquire(root string) func() {
	_ = root // retained in the API to document the protected storage boundary
	directoryMutationMu.Lock()
	var once sync.Once
	return func() {
		once.Do(func() {
			directoryMutationMu.Unlock()
		})
	}
}
