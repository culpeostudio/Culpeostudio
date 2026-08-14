package wireguard

import (
	"strings"
	"testing"
)

func TestGenerateKeyPairProducesUsableKeys(t *testing.T) {
	pair, err := GenerateKeyPair()
	if err != nil {
		t.Fatalf("GenerateKeyPair: %v", err)
	}
	if !ValidKey(pair.PrivateKey) {
		t.Errorf("private key is not a valid WireGuard key: %q", pair.PrivateKey)
	}
	if !ValidKey(pair.PublicKey) {
		t.Errorf("public key is not a valid WireGuard key: %q", pair.PublicKey)
	}
	if pair.PrivateKey == pair.PublicKey {
		t.Error("public key equals private key")
	}

	second, err := GenerateKeyPair()
	if err != nil {
		t.Fatalf("GenerateKeyPair: %v", err)
	}
	if second.PrivateKey == pair.PrivateKey {
		t.Error("two key pairs came out identical")
	}
}

func TestTunnelAddressesSplitsTheNetwork(t *testing.T) {
	node, client, allowed, err := TunnelAddresses("10.77.0.0/24")
	if err != nil {
		t.Fatalf("TunnelAddresses: %v", err)
	}
	if node != "10.77.0.1" {
		t.Errorf("node address = %q, want 10.77.0.1", node)
	}
	if client != "10.77.0.2/32" {
		t.Errorf("client address = %q, want 10.77.0.2/32", client)
	}
	if allowed != "10.77.0.0/24" {
		t.Errorf("allowed ips = %q, want 10.77.0.0/24", allowed)
	}
}

func TestTunnelAddressesDefaultsAndRejects(t *testing.T) {
	node, _, _, err := TunnelAddresses("")
	if err != nil {
		t.Fatalf("empty network should fall back to the default: %v", err)
	}
	if node != "10.77.0.1" {
		t.Errorf("default node address = %q, want 10.77.0.1", node)
	}
	if _, _, _, err := TunnelAddresses("10.77.0.0/31"); err == nil {
		t.Error("a /31 has no room for two addresses and should be rejected")
	}
	if _, _, _, err := TunnelAddresses("nonsense"); err == nil {
		t.Error("an unparsable network should be rejected")
	}
}

func TestInterfaceNameFitsLinuxLimit(t *testing.T) {
	name := InterfaceName("A1b2C3d4e5f6")
	if len(name) > 15 {
		t.Errorf("interface name %q is %d characters, Linux allows 15", name, len(name))
	}
	if name != "culpeo-a1b2c3d4" {
		t.Errorf("interface name = %q, want culpeo-a1b2c3d4", name)
	}
	if got := InterfaceName("!!!"); got != "culpeo-node" {
		t.Errorf("a name with nothing usable in it = %q, want culpeo-node", got)
	}
}

func TestPairRendersBothSidesAndRoundTrips(t *testing.T) {
	pairing, err := Pair(PairingRequest{
		NodeID:      "abc123def456",
		Name:        "Werkstatt",
		Token:       "pairing-token",
		GRPCPort:    50051,
		GatewayPort: 8091,
		Endpoint:    "node.example.org",
	})
	if err != nil {
		t.Fatalf("Pair: %v", err)
	}

	// Each side has to carry the other's public key, or the handshake cannot
	// happen. This is the one property a config typo would silently break.
	if !strings.Contains(pairing.NodeConfig, pairing.ClientKeys.PublicKey) {
		t.Error("the node config does not list the Studio as a peer")
	}
	if !strings.Contains(pairing.ClientConfig, pairing.NodeKeys.PublicKey) {
		t.Error("the Studio config does not list the node as a peer")
	}
	if strings.Contains(pairing.NodeConfig, pairing.ClientKeys.PrivateKey) {
		t.Error("the node config leaked the Studio's private key")
	}
	if !strings.Contains(pairing.ClientConfig, "Endpoint = node.example.org:51820") {
		t.Errorf("the Studio config has no dialable endpoint:\n%s", pairing.ClientConfig)
	}
	if !strings.Contains(pairing.NodeConfig, "ListenPort = 51820") {
		t.Errorf("the node config does not listen anywhere:\n%s", pairing.NodeConfig)
	}
	if strings.Contains(pairing.ClientConfig, "ListenPort") {
		t.Error("the Studio side is the dialer and should not pin a listen port")
	}

	decoded, err := DecodeJoinCode(pairing.JoinCode)
	if err != nil {
		t.Fatalf("DecodeJoinCode: %v", err)
	}
	if decoded.NodeID != "abc123def456" || decoded.Token != "pairing-token" {
		t.Errorf("join code lost its identity: %+v", decoded)
	}
	if decoded.NodeAddress != "10.77.0.1" {
		t.Errorf("join code node address = %q, want 10.77.0.1", decoded.NodeAddress)
	}
	if decoded.TunnelConfig != pairing.ClientConfig {
		t.Error("the join code does not carry the config that was rendered for the Studio")
	}
}

func TestPairNeedsAnEndpoint(t *testing.T) {
	_, err := Pair(PairingRequest{NodeID: "abc", Token: "t"})
	if err == nil {
		t.Fatal("pairing without a public address should fail rather than render a config nobody can dial")
	}
	if !strings.Contains(err.Error(), "CULPEO_NODE_WG_ENDPOINT") {
		t.Errorf("the error should name the setting that fixes it, got: %v", err)
	}
}

func TestDecodeJoinCodeRejectsJunk(t *testing.T) {
	cases := map[string]string{
		"empty":       "",
		"foreign":     "some-other-tool-code",
		"broken":      joinCodePrefix + "!!!not-base64!!!",
		"not-json":    joinCodePrefix + "aGVsbG8",
		"no-tunnel":   mustEncode(t, JoinCode{Version: JoinCodeVersion, NodeID: "a", Token: "b", NodeAddress: "10.77.0.1", PeerPublicKey: validTestKey(t)}),
		"old-version": mustEncode(t, JoinCode{Version: 99, NodeID: "a", Token: "b"}),
	}
	for name, code := range cases {
		if _, err := DecodeJoinCode(code); err == nil {
			t.Errorf("%s: expected a rejection", name)
		}
	}
}

func TestDecodeJoinCodeToleratesWrappedPaste(t *testing.T) {
	pairing, err := Pair(PairingRequest{NodeID: "abc123", Token: "t", Endpoint: "10.0.0.5:51820"})
	if err != nil {
		t.Fatalf("Pair: %v", err)
	}
	wrapped := "  " + pairing.JoinCode[:20] + "\n" + pairing.JoinCode[20:] + "\n"
	decoded, err := DecodeJoinCode(wrapped)
	if err != nil {
		t.Fatalf("a code that arrived wrapped should still decode: %v", err)
	}
	if decoded.NodeID != "abc123" {
		t.Errorf("node id = %q, want abc123", decoded.NodeID)
	}
}

func mustEncode(t *testing.T, code JoinCode) string {
	t.Helper()
	encoded, err := code.Encode()
	if err != nil {
		t.Fatalf("Encode: %v", err)
	}
	return encoded
}

func validTestKey(t *testing.T) string {
	t.Helper()
	pair, err := GenerateKeyPair()
	if err != nil {
		t.Fatalf("GenerateKeyPair: %v", err)
	}
	return pair.PublicKey
}
