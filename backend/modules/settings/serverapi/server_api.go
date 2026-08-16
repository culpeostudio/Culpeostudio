// Package serverapi contains server and API setting handlers for the settings module.
package serverapi

import (
	"fmt"
	"net/http"
	"time"
)

// ServerApiHandler encapsulates API provider connectivity tests and server API configuration functions.
type ServerApiHandler struct{}

// New returns a new ServerApiHandler instance.
func New() *ServerApiHandler {
	return &ServerApiHandler{}
}

// TestHuggingFace tests connection to HuggingFace API.
func (h *ServerApiHandler) TestHuggingFace(token string) (bool, string) {
	client := &http.Client{Timeout: 10 * time.Second}
	if token != "" {
		req, err := http.NewRequest("GET", "https://huggingface.co/api/whoami", nil)
		if err != nil {
			return false, err.Error()
		}
		req.Header.Set("Authorization", "Bearer "+token)
		resp, err := client.Do(req)
		if err != nil {
			return false, "Verbindungsfehler: " + err.Error()
		}
		defer resp.Body.Close()

		if resp.StatusCode == 200 {
			return true, "Berechtigt und erreichbar"
		}
		if resp.StatusCode == 401 {
			return false, "Ungültiger Token (401)"
		}
		return false, fmt.Sprintf("Unerwarteter Status: %d", resp.StatusCode)
	} else {
		req, err := http.NewRequest("GET", "https://huggingface.co/api/models?limit=1", nil)
		if err != nil {
			return false, err.Error()
		}
		resp, err := client.Do(req)
		if err != nil {
			return false, "Dienst nicht erreichbar"
		}
		defer resp.Body.Close()
		if resp.StatusCode == 200 {
			return true, "Erreichbar (kein Token)"
		}
		return false, fmt.Sprintf("Dienst nicht erreichbar: %d", resp.StatusCode)
	}
}

// TestOpenRouter tests connection to OpenRouter API.
func (h *ServerApiHandler) TestOpenRouter(token string) (bool, string) {
	client := &http.Client{Timeout: 10 * time.Second}
	if token != "" {
		req, err := http.NewRequest("GET", "https://openrouter.ai/api/v1/auth/key", nil)
		if err != nil {
			return false, err.Error()
		}
		req.Header.Set("Authorization", "Bearer "+token)
		resp, err := client.Do(req)
		if err != nil {
			return false, "Verbindungsfehler: " + err.Error()
		}
		defer resp.Body.Close()

		if resp.StatusCode == 200 {
			return true, "Berechtigt und erreichbar"
		}
		if resp.StatusCode == 401 {
			return false, "Ungültiger Token (401)"
		}
		return false, fmt.Sprintf("Unerwarteter Status: %d", resp.StatusCode)
	} else {
		req, err := http.NewRequest("GET", "https://openrouter.ai/api/v1/models", nil)
		if err != nil {
			return false, err.Error()
		}
		resp, err := client.Do(req)
		if err != nil {
			return false, "Dienst nicht erreichbar"
		}
		defer resp.Body.Close()
		if resp.StatusCode == 200 {
			return true, "Erreichbar (kein Token)"
		}
		return false, fmt.Sprintf("Dienst nicht erreichbar: %d", resp.StatusCode)
	}
}

// TestFeatherless tests connection to Featherless API.
func (h *ServerApiHandler) TestFeatherless(token string) (bool, string) {
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("GET", "https://api.featherless.ai/v1/models", nil)
	if err != nil {
		return false, err.Error()
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := client.Do(req)
	if err != nil {
		return false, "Verbindungsfehler: " + err.Error()
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		if token != "" {
			return true, "Berechtigt und erreichbar"
		}
		return true, "Erreichbar (öffentlich)"
	}
	if resp.StatusCode == 401 {
		if token != "" {
			return false, "Ungültiger Token (401)"
		}
		return true, "Erreichbar (erfordert Token)"
	}
	return false, fmt.Sprintf("Unerwarteter Status: %d", resp.StatusCode)
}
