package metasearch

import "errors"

var ErrSearch = errors.New("metasearch: suchfehler")

var ErrRatelimit = errors.New("metasearch: ratelimit")

var ErrTimeout = errors.New("metasearch: timeout")

type SearchError struct {
	Cause error
	Msg   string
}

func (e *SearchError) Error() string {
	if e.Msg == "" {
		return e.Cause.Error()
	}
	if e.Cause == nil {
		return e.Msg
	}
	return e.Msg + ": " + e.Cause.Error()
}

func (e *SearchError) Unwrap() error {
	if e.Cause != nil {
		return e.Cause
	}
	return ErrSearch
}

func NewError(cause error, msg string) *SearchError {
	return &SearchError{Cause: cause, Msg: msg}
}

func IsTimeout(err error) bool {
	return errors.Is(err, ErrTimeout) ||
		(err != nil && contains(err.Error(), "timed out"))
}

func IsRatelimit(err error) bool {
	return errors.Is(err, ErrRatelimit)
}
