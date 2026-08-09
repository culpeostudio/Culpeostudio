package engineruntime

import "sync"

type RingBuffer struct {
	mu  sync.Mutex
	max int
	buf []byte
}

func NewRingBuffer(maxBytes int) *RingBuffer {
	if maxBytes < 1 {
		maxBytes = 64 * 1024
	}
	return &RingBuffer{max: maxBytes}
}

func (r *RingBuffer) Write(p []byte) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	written := len(p)
	if len(p) >= r.max {
		r.buf = append(r.buf[:0], p[len(p)-r.max:]...)
		return written, nil
	}
	if overflow := len(r.buf) + len(p) - r.max; overflow > 0 {
		copy(r.buf, r.buf[overflow:])
		r.buf = r.buf[:len(r.buf)-overflow]
	}
	r.buf = append(r.buf, p...)
	return written, nil
}

func (r *RingBuffer) String() string {
	r.mu.Lock()
	defer r.mu.Unlock()
	return string(append([]byte(nil), r.buf...))
}

func (r *RingBuffer) Bytes() []byte {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]byte(nil), r.buf...)
}
