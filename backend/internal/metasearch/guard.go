package metasearch

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strings"
)

// ErrBlockedURL wird geliefert, wenn eine Ziel-URL nicht nach aussen
// zeigt und deshalb nicht abgerufen werden darf.
var ErrBlockedURL = errors.New("metasearch: ziel-url ist nicht oeffentlich erreichbar")

// cgnatNet ist der Carrier-Grade-NAT-Bereich 100.64.0.0/10. net.IP
// kennt ihn nicht als "privat", er gehoert hier aber dazu.
var cgnatNet = &net.IPNet{IP: net.IPv4(100, 64, 0, 0), Mask: net.CIDRMask(10, 32)}

// GuardPublicURL prueft, ob rawURL gefahrlos vom Server abgerufen werden
// darf. Erlaubt sind ausschliesslich http/https auf Hosts, die zu
// oeffentlich routbaren IP-Adressen aufloesen.
//
// Damit werden SSRF-Angriffe gegen Dienste auf dem Host selbst
// (127.0.0.1), im lokalen Netz (10/8, 192.168/16, ...) und gegen
// Cloud-Metadaten-Endpunkte (169.254.169.254) abgewehrt.
//
// Restrisiko: zwischen dieser Pruefung und dem eigentlichen Dial liegt
// eine zweite DNS-Aufloesung, ein DNS-Rebinding-Angreifer koennte das
// Zeitfenster nutzen. Fuer einen vollstaendigen Schutz muesste die
// Pruefung im DialContext des Transports sitzen.
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

	// Literale IP braucht keinen Lookup.
	if ip := net.ParseIP(host); ip != nil {
		if !isPublicIP(ip) {
			return fmt.Errorf("%w: %s", ErrBlockedURL, ip)
		}
		return nil
	}

	// "localhost" und Konsorten loesen zwar meist auf 127.0.0.1 auf,
	// wir lehnen sie aber schon vor dem Lookup ab.
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
	// Eine einzige nicht-oeffentliche Adresse reicht zum Ablehnen: der
	// Dialer koennte sich genau die aussuchen.
	for _, ip := range ips {
		if !isPublicIP(ip) {
			return fmt.Errorf("%w: %s loest auf %s auf", ErrBlockedURL, host, ip)
		}
	}
	return nil
}

// isPublicIP meldet, ob ip oeffentlich routbar ist.
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

// isLocalHostname faengt die ueblichen Namen fuer den eigenen Host ab.
func isLocalHostname(host string) bool {
	h := strings.ToLower(strings.TrimSuffix(host, "."))
	return h == "localhost" || strings.HasSuffix(h, ".localhost") ||
		h == "localhost.localdomain" || strings.HasSuffix(h, ".local") ||
		strings.HasSuffix(h, ".internal")
}
