package nodeconnection

import (
	"crypto/sha256"
	"encoding/hex"
	"testing"
)

func TestPinnedTLSConfigVerifiesOnlyItsLeafFingerprint(t *testing.T) {
	rawCertificate := []byte("test-node-certificate")
	fingerprint := sha256.Sum256(rawCertificate)
	config, err := PinnedTLSConfig(hex.EncodeToString(fingerprint[:]))
	if err != nil {
		t.Fatalf("PinnedTLSConfig: %v", err)
	}
	if err := config.VerifyPeerCertificate([][]byte{rawCertificate}, nil); err != nil {
		t.Fatalf("matching certificate rejected: %v", err)
	}
	if err := config.VerifyPeerCertificate([][]byte{[]byte("other-certificate")}, nil); err == nil {
		t.Fatal("unrelated certificate was accepted")
	}
}
