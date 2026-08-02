package metasearch

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strings"
)

var ErrBlockedURL = errors.New("metasearch: ziel-url ist nicht oeffentlich erreichbar")

var cgnatNet = &net.IPNet{IP: net.IPv4(100, 64, 0, 0), Mask: net.CIDRMask(10, 32)}

func GuardPublicURL(ctx context.Context, rawURL string) error {
	u, err := url.Parse(strings.TrimSpace(rawURL))
	if err != nil {
		return fmt.Errorf("%w: url nicht parsebar", ErrBlockedURL)
	}
	switch strings.ToLower(u.Scheme) {
	case "http", "https":
	default:
		return fmt.Errorf("%w: schema %q nicht erlaubt", ErrBlockedURL, u.Scheme)
	}

	host := u.Hostname()
	if host == "" {
		return fmt.Errorf("%w: kein host angegeben", ErrBlockedURL)
	}

	if ip := net.ParseIP(host); ip != nil {
		if !isPublicIP(ip) {
			return fmt.Errorf("%w: %s", ErrBlockedURL, ip)
		}
		return nil
	}

	if isLocalHostname(host) {
		return fmt.Errorf("%w: hostname %q", ErrBlockedURL, host)
	}

	ips, err := net.DefaultResolver.LookupIP(ctx, "ip", host)
	if err != nil {
		return fmt.Errorf("%w: dns-lookup fuer %q fehlgeschlagen", ErrBlockedURL, host)
	}
	if len(ips) == 0 {
		return fmt.Errorf("%w: keine adressen fuer %q", ErrBlockedURL, host)
	}

	for _, ip := range ips {
		if !isPublicIP(ip) {
			return fmt.Errorf("%w: %s loest auf %s auf", ErrBlockedURL, host, ip)
		}
	}
	return nil
}

func isPublicIP(ip net.IP) bool {
	if ip == nil || ip.IsUnspecified() || ip.IsLoopback() || ip.IsPrivate() ||
		ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() ||
		ip.IsInterfaceLocalMulticast() || ip.IsMulticast() {
		return false
	}
	if v4 := ip.To4(); v4 != nil && cgnatNet.Contains(v4) {
		return false
	}
	return true
}

func isLocalHostname(host string) bool {
	h := strings.ToLower(strings.TrimSuffix(host, "."))
	return h == "localhost" || strings.HasSuffix(h, ".localhost") ||
		h == "localhost.localdomain" || strings.HasSuffix(h, ".local") ||
		strings.HasSuffix(h, ".internal")
}
