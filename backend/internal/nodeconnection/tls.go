package nodeconnection

import (
	"crypto/sha256"
	"crypto/subtle"
	"crypto/tls"
	"crypto/x509"
	"encoding/hex"
	"errors"
	"fmt"
)

// PinnedTLSConfig creates the TLS settings for a direct Node connection. A
// Node carries a self-signed certificate, so certificate-authority and DNS
// name checks are intentionally replaced by an exact SHA-256 pin from the
// connection link.
func PinnedTLSConfig(rawFingerprint string) (*tls.Config, error) {
	fingerprint, err := NormalizeFingerprint(rawFingerprint)
	if err != nil {
		return nil, err
	}
	expected, err := hex.DecodeString(fingerprint)
	if err != nil {
		// NormalizeFingerprint already makes this unreachable. Keep the guard
		// so a later validation change cannot accidentally create an unpinned
		// TLS connection.
		return nil, fmt.Errorf("TLS-Fingerprint dekodieren: %w", err)
	}
	verify := func(rawCerts [][]byte) error {
		if len(rawCerts) == 0 {
			return errors.New("Node hat kein TLS-Zertifikat gesendet")
		}
		actual := sha256.Sum256(rawCerts[0])
		if subtle.ConstantTimeCompare(actual[:], expected) != 1 {
			return errors.New("TLS-Zertifikat stimmt nicht mit dem Node-Verbindungslink ueberein")
		}
		return nil
	}
	return &tls.Config{
		MinVersion:         tls.VersionTLS12,
		InsecureSkipVerify: true, // verification is the pin directly above
		VerifyPeerCertificate: func(rawCerts [][]byte, _ [][]*x509.Certificate) error {
			return verify(rawCerts)
		},
		// TLS session resumption can skip VerifyPeerCertificate. VerifyConnection
		// covers that path too, so every connection is still tied to this leaf.
		VerifyConnection: func(state tls.ConnectionState) error {
			if len(state.PeerCertificates) == 0 {
				return errors.New("Node hat kein TLS-Zertifikat gesendet")
			}
			return verify([][]byte{state.PeerCertificates[0].Raw})
		},
	}, nil
}
