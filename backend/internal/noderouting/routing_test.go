package noderouting

import "testing"

func TestTargetEndpointAndGatewayURL(t *testing.T) {
	target := Target{Address: "10.77.0.1", GRPCPort: 50051, GatewayPort: 8091}
	if got := target.Endpoint(); got != "10.77.0.1:50051" {
		t.Errorf("Endpoint() = %q", got)
	}
	if got := target.GatewayURL(); got != "http://10.77.0.1:8091" {
		t.Errorf("GatewayURL() = %q", got)
	}

	reported := Target{Address: "10.77.0.1", GatewayBaseURL: "http://10.77.0.1:9000/"}
	if got := reported.GatewayURL(); got != "http://10.77.0.1:9000" {
		t.Errorf("GatewayURL() with a reported base = %q", got)
	}

	if got := (Target{Address: "fd00::1"}).Endpoint(); got != "[fd00::1]:50051" {
		t.Errorf("IPv6 Endpoint() = %q", got)
	}
}

func TestQualifiedIDsRoundTrip(t *testing.T) {
	qualified := Qualify("node-1", "model-1")
	if qualified != "n:node-1:model-1" {
		t.Fatalf("Qualify() = %q", qualified)
	}
	nodeID, localID, remote := Split(qualified)
	if !remote || nodeID != "node-1" || localID != "model-1" {
		t.Fatalf("Split(%q) = (%q, %q, %t)", qualified, nodeID, localID, remote)
	}
	if got := NodeIDOf(qualified); got != "node-1" {
		t.Errorf("NodeIDOf() = %q", got)
	}
	if !IsRemote(qualified) {
		t.Error("IsRemote() = false")
	}
}
