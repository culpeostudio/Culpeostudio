// Package wireguard builds the tunnel between a Studio and one of its nodes:
// the key pairs, the two config files, the join code that carries them from
// the node to the Studio, and what little can be said about an interface
// without root.
//
// Bringing an interface up is deliberately not something this package does on
// its own. It needs root on every platform, and a desktop app that quietly
// acquires root is worse than one that shows the command. Raise reports what
// would run and runs it only behind a privilege helper the user answers.
package wireguard

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"

	"golang.org/x/crypto/curve25519"
)

// KeyPair is a WireGuard key pair in the base64 form the config files use.
type KeyPair struct {
	PrivateKey string
	PublicKey  string
}

// GenerateKeyPair draws a new Curve25519 key pair. The private key is clamped
// the way WireGuard clamps it, so the value written into a config is the value
// the kernel would derive the public key from.
func GenerateKeyPair() (KeyPair, error) {
	private := make([]byte, curve25519.ScalarSize)
	if _, err := rand.Read(private); err != nil {
		return KeyPair{}, fmt.Errorf("WireGuard-Schluessel erzeugen: %w", err)
	}
	private[0] &= 248
	private[31] &= 127
	private[31] |= 64

	public, err := curve25519.X25519(private, curve25519.Basepoint)
	if err != nil {
		return KeyPair{}, fmt.Errorf("WireGuard-Public-Key ableiten: %w", err)
	}
	return KeyPair{
		PrivateKey: base64.StdEncoding.EncodeToString(private),
		PublicKey:  base64.StdEncoding.EncodeToString(public),
	}, nil
}

// ValidKey reports whether a string is shaped like a WireGuard key: 32 bytes,
// base64. It is what the join code is checked against, because a truncated
// paste is the likeliest way a config ends up unusable.
func ValidKey(value string) bool {
	raw, err := base64.StdEncoding.DecodeString(value)
	return err == nil && len(raw) == curve25519.ScalarSize
}
