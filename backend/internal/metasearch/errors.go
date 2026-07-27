// Package metasearch bietet die PhiloSearch-Metasuch-Engine.
//
// Es aggregiert Treffer aus unterschiedlichen Web-Suchbackends
// (Bing, Brave, DuckDuckGo, Google, Wikipedia, ...). Die Library
// ist das Go-Aequivalent des urspruenglich in Python geschriebenen
// ddgs-Projekts und wurde als interne Infrastruktur fuer das
// PhiloSearch-Modul in PhiloEngine ausgelegt.
package metasearch

import "errors"

// ErrSearch ist die Basis fuer alle Metasearch-Fehler.
var ErrSearch = errors.New("metasearch: suchfehler")

// ErrRatelimit wird ausgeloest, wenn ein Backend mit HTTP 429 antwortet.
var ErrRatelimit = errors.New("metasearch: ratelimit")

// ErrTimeout wird ausgeloest, wenn ein Backend nicht innerhalb des
// konfigurierten Timeouts antwortet.
var ErrTimeout = errors.New("metasearch: timeout")

// SearchError verpackt einen Basisfehler mit zusaetzlichem Kontext.
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

// NewError erzeugt einen neuen SearchError.
func NewError(cause error, msg string) *SearchError {
	return &SearchError{Cause: cause, Msg: msg}
}

// IsTimeout prueft, ob ein Fehler auf einen Timeout zurueckzufuehren ist.
func IsTimeout(err error) bool {
	return errors.Is(err, ErrTimeout) ||
		(err != nil && contains(err.Error(), "timed out"))
}

// IsRatelimit prueft, ob ein Fehler auf ein Rate-Limit zurueckzufuehren ist.
func IsRatelimit(err error) bool {
	return errors.Is(err, ErrRatelimit)
}
