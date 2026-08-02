package metasearch

import (
	"context"
	"errors"
	"testing"
)

func TestGuardPublicURLBlocksInternalTargets(t *testing.T) {
	blocked := []struct {
		name string
		url  string
	}{
		{"loopback v4", "http://127.0.0.1:8080/admin"},
		{"loopback v6", "http://[::1]:8080/admin"},
		{"localhost", "http://localhost:3000/"},
		{"localhost-subdomain", "http://api.localhost/"},
		{"mdns", "http://nas.local/"},
		{"privat 10/8", "http://10.0.0.5/"},
		{"privat 192.168/16", "https://192.168.1.1/router"},
		{"privat 172.16/12", "http://172.16.0.1/"},
		{"cloud-metadaten", "http://169.254.169.254/latest/meta-data/"},
		{"cgnat", "http://100.64.0.1/"},
		{"unspecified", "http://0.0.0.0/"},
		{"ipv6 ula", "http://[fd00::1]/"},
		{"file-schema", "file:///etc/passwd"},
		{"gopher-schema", "gopher://127.0.0.1:11211/"},
		{"kein host", "http:///pfad"},
	}
	for _, tc := range blocked {
		t.Run(tc.name, func(t *testing.T) {
			err := GuardPublicURL(context.Background(), tc.url)
			if err == nil {
				t.Fatalf("GuardPublicURL(%q) = nil, erwartet ErrBlockedURL", tc.url)
			}
			if !errors.Is(err, ErrBlockedURL) {
				t.Fatalf("GuardPublicURL(%q) = %v, erwartet ErrBlockedURL", tc.url, err)
			}
		})
	}
}

func TestGuardPublicURLAllowsPublicIP(t *testing.T) {

	for _, raw := range []string{"https://8.8.8.8/", "http://1.1.1.1/pfad?q=1", "https://[2606:4700:4700::1111]/"} {
		if err := GuardPublicURL(context.Background(), raw); err != nil {
			t.Errorf("GuardPublicURL(%q) = %v, erwartet nil", raw, err)
		}
	}
}

func TestIsPublicIPNil(t *testing.T) {
	if isPublicIP(nil) {
		t.Error("isPublicIP(nil) = true, erwartet false")
	}
}
