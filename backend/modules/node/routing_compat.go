package node

import "github.com/culpeohq/backend/internal/noderouting"

// Target and Directory remain aliases so existing callers of modules/node keep
// compiling while consumers can depend on the small routing contract instead.
type Target = noderouting.Target
type Directory = noderouting.Directory
