package nodeconnection

import (
	"strings"
	"testing"
)

const testFingerprint = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

func TestConnectionRoundTripNormalizesIPv6AndFingerprint(t *testing.T) {
	encoded, err := Encode(Connection{
		NodeID:      "node-workshop-01",
		Endpoint:    "[fd12:3456::9]:50051",
		Fingerprint: "sha256:" + strings.ToUpper(testFingerprint),
		Token:       "a-very-long-node-token-1234567890",
		Name:        " Werkstatt ",
	})
	if err != nil {
		t.Fatalf("Encode: %v", err)
	}
	decoded, err := Decode("  " + encoded[:24] + "\n" + encoded[24:] + " ")
	if err != nil {
		t.Fatalf("Decode: %v", err)
	}
	if decoded.Endpoint != "[fd12:3456::9]:50051" {
		t.Errorf("Endpoint = %q", decoded.Endpoint)
	}
	if decoded.NodeID != "node-workshop-01" {
		t.Errorf("NodeID = %q", decoded.NodeID)
	}
	if decoded.Fingerprint != testFingerprint {
		t.Errorf("Fingerprint = %q", decoded.Fingerprint)
	}
	if decoded.Name != "Werkstatt" {
		t.Errorf("Name = %q", decoded.Name)
	}
}

func TestConnectionRejectsUnsafeOrMalformedValues(t *testing.T) {
	cases := []Connection{
		{Endpoint: "node.example.org", Fingerprint: testFingerprint, Token: "a-very-long-node-token-1234567890"},
		{Endpoint: "0.0.0.0:50051", Fingerprint: testFingerprint, Token: "a-very-long-node-token-1234567890"},
		{Endpoint: "node.example.org:50051", Fingerprint: "not-a-fingerprint", Token: "a-very-long-node-token-1234567890"},
		{Endpoint: "node.example.org:50051", Fingerprint: testFingerprint, Token: "too-short"},
		{Endpoint: "node.example.org:50051", Fingerprint: testFingerprint, Token: "contains a space token-1234567890"},
		{NodeID: "bad node id", Endpoint: "node.example.org:50051", Fingerprint: testFingerprint, Token: "a-very-long-node-token-1234567890"},
	}
	for _, connection := range cases {
		if _, err := Encode(connection); err == nil {
			t.Errorf("Encode(%+v) succeeded", connection)
		}
	}
	if _, err := Decode("not-a-node-link"); err == nil {
		t.Error("Decode accepted a foreign link")
	}
}
