// Package nodecert owns the self-signed certificate of a standalone Culpeo
// Node. The Studio pins its SHA-256 fingerprint from the connection link, so
// no public certificate authority or DNS-specific certificate is required.
package nodecert

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/hex"
	"encoding/pem"
	"fmt"
	"math/big"
	"os"
	"path/filepath"
	"time"
)

const (
	certificateName = "node-cert.pem"
	privateKeyName  = "node-key.pem"
)

// Certificate describes the persisted TLS credentials and the fingerprint a
// Studio pins before it sends the Node token.
type Certificate struct {
	CertificatePath string
	PrivateKeyPath  string
	Fingerprint     string
}

// Ensure loads a Node's existing certificate or creates a self-signed P-256
// certificate once. A partial credential set is an error rather than an
// invitation to regenerate: silently changing it would invalidate every
// already paired Studio.
func Ensure(dataDir string) (Certificate, error) {
	if dataDir == "" {
		return Certificate{}, fmt.Errorf("Node-Datenordner fehlt")
	}
	directory := filepath.Join(filepath.Clean(dataDir), "tls")
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return Certificate{}, fmt.Errorf("Node-TLS-Ordner anlegen: %w", err)
	}
	certPath := filepath.Join(directory, certificateName)
	keyPath := filepath.Join(directory, privateKeyName)
	_, certErr := os.Stat(certPath)
	_, keyErr := os.Stat(keyPath)
	if certErr == nil && keyErr == nil {
		return load(certPath, keyPath)
	}
	if certErr == nil || keyErr == nil {
		return Certificate{}, fmt.Errorf("Node-TLS-Anmeldung ist unvollstaendig; %s und %s muessen gemeinsam vorhanden sein", certPath, keyPath)
	}
	if !os.IsNotExist(certErr) {
		return Certificate{}, fmt.Errorf("Node-Zertifikat pruefen: %w", certErr)
	}
	if !os.IsNotExist(keyErr) {
		return Certificate{}, fmt.Errorf("Node-Schluessel pruefen: %w", keyErr)
	}
	if err := generate(certPath, keyPath); err != nil {
		return Certificate{}, err
	}
	return load(certPath, keyPath)
}

func generate(certPath, keyPath string) error {
	privateKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return fmt.Errorf("Node-TLS-Schluessel erzeugen: %w", err)
	}
	serialLimit := new(big.Int).Lsh(big.NewInt(1), 128)
	serial, err := rand.Int(rand.Reader, serialLimit)
	if err != nil {
		return fmt.Errorf("Node-Zertifikatsnummer erzeugen: %w", err)
	}
	now := time.Now()
	template := x509.Certificate{
		SerialNumber:          serial,
		Subject:               pkix.Name{CommonName: "culpeo-node"},
		NotBefore:             now.Add(-time.Hour),
		NotAfter:              now.AddDate(10, 0, 0),
		KeyUsage:              x509.KeyUsageDigitalSignature | x509.KeyUsageKeyEncipherment,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
	}
	der, err := x509.CreateCertificate(rand.Reader, &template, &template, &privateKey.PublicKey, privateKey)
	if err != nil {
		return fmt.Errorf("Node-Zertifikat erzeugen: %w", err)
	}
	keyDER, err := x509.MarshalPKCS8PrivateKey(privateKey)
	if err != nil {
		return fmt.Errorf("Node-TLS-Schluessel kodieren: %w", err)
	}
	if err := writePrivateFile(keyPath, pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: keyDER})); err != nil {
		return fmt.Errorf("Node-TLS-Schluessel schreiben: %w", err)
	}
	if err := writePrivateFile(certPath, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der})); err != nil {
		_ = os.Remove(keyPath)
		return fmt.Errorf("Node-Zertifikat schreiben: %w", err)
	}
	return nil
}

func load(certPath, keyPath string) (Certificate, error) {
	certificatePEM, err := os.ReadFile(certPath)
	if err != nil {
		return Certificate{}, fmt.Errorf("Node-Zertifikat lesen: %w", err)
	}
	if _, err := tls.LoadX509KeyPair(certPath, keyPath); err != nil {
		return Certificate{}, fmt.Errorf("Node-TLS-Anmeldung laden: %w", err)
	}
	block, _ := pem.Decode(certificatePEM)
	if block == nil || block.Type != "CERTIFICATE" {
		return Certificate{}, fmt.Errorf("Node-Zertifikat ist keine PEM-Zertifikatsdatei")
	}
	if _, err := x509.ParseCertificate(block.Bytes); err != nil {
		return Certificate{}, fmt.Errorf("Node-Zertifikat ist ungueltig: %w", err)
	}
	digest := sha256.Sum256(block.Bytes)
	return Certificate{
		CertificatePath: certPath,
		PrivateKeyPath:  keyPath,
		Fingerprint:     hex.EncodeToString(digest[:]),
	}, nil
}

func writePrivateFile(path string, contents []byte) error {
	temporary := path + ".tmp"
	if err := os.WriteFile(temporary, contents, 0o600); err != nil {
		return err
	}
	if err := os.Chmod(temporary, 0o600); err != nil {
		_ = os.Remove(temporary)
		return err
	}
	if err := os.Rename(temporary, path); err != nil {
		_ = os.Remove(temporary)
		return err
	}
	return nil
}
