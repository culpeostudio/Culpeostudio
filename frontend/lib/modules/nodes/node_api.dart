import '../../core/api_client.dart';
import '../../generated/culpeostudio/node/v1/node.pbgrpc.dart' as nodepb;

/// How a node last answered.
enum NodeState { unknown, online, offline, unauthorized, disabled }

/// What the WireGuard interface for a node is doing.
enum NodeTunnelState { unknown, down, up, unavailable }

/// The tunnel to one node, as far as the backend can see it without root.
class NodeTunnel {
  final String interfaceName;
  final String configPath;
  final String localAddress;
  final String endpoint;
  final String peerPublicKey;
  final NodeTunnelState state;
  final String bringUpCommand;
  final String bringDownCommand;
  final String statusMessage;
  final DateTime? lastHandshakeAt;

  const NodeTunnel({
    this.interfaceName = '',
    this.configPath = '',
    this.localAddress = '',
    this.endpoint = '',
    this.peerPublicKey = '',
    this.state = NodeTunnelState.unknown,
    this.bringUpCommand = '',
    this.bringDownCommand = '',
    this.statusMessage = '',
    this.lastHandshakeAt,
  });

  /// True when the Studio wrote this config and can therefore act on it. A
  /// tunnel somebody set up by hand is shown but never touched.
  bool get isManaged => configPath.trim().isNotEmpty;

  factory NodeTunnel.fromProto(nodepb.NodeTunnel message) {
    return NodeTunnel(
      interfaceName: message.interfaceName,
      configPath: message.configPath,
      localAddress: message.localAddress,
      endpoint: message.endpoint,
      peerPublicKey: message.peerPublicKey,
      state: _tunnelStateFromProto(message.state),
      bringUpCommand: message.bringUpCommand,
      bringDownCommand: message.bringDownCommand,
      statusMessage: message.statusMessage,
      lastHandshakeAt: message.hasLastHandshakeAt()
          ? message.lastHandshakeAt.toDateTime().toLocal()
          : null,
    );
  }
}

/// One machine this Studio may download to and run models on.
class StudioNode {
  final String id;
  final String name;
  final String address;
  final int grpcPort;
  final int gatewayPort;
  final bool enabled;
  final NodeState state;
  final String statusMessage;
  final String version;
  final String modelDir;
  final int modelCount;
  final int instanceCount;
  final int diskFreeBytes;
  final NodeTunnel tunnel;
  final DateTime? lastSeenAt;

  final String gpuName;
  final int vramGb;
  final int ramGb;

  const StudioNode({
    required this.id,
    required this.name,
    this.address = '',
    this.grpcPort = 0,
    this.gatewayPort = 0,
    this.enabled = true,
    this.state = NodeState.unknown,
    this.statusMessage = '',
    this.version = '',
    this.modelDir = '',
    this.modelCount = 0,
    this.instanceCount = 0,
    this.diskFreeBytes = 0,
    this.tunnel = const NodeTunnel(),
    this.lastSeenAt,
    this.gpuName = '',
    this.vramGb = 0,
    this.ramGb = 0,
  });

  /// A node can only be given work when it is switched on and answering.
  bool get isUsable => enabled && state == NodeState.online;

  factory StudioNode.fromProto(nodepb.Node message) {
    final hardware = message.hasHardware() ? message.hardware : null;
    return StudioNode(
      id: message.id,
      name: message.name,
      address: message.address,
      grpcPort: message.grpcPort,
      gatewayPort: message.gatewayPort,
      enabled: message.enabled,
      state: _nodeStateFromProto(message.state),
      statusMessage: message.statusMessage,
      version: message.version,
      modelDir: message.modelDir,
      modelCount: message.modelCount,
      instanceCount: message.instanceCount,
      diskFreeBytes: message.diskFreeBytes.toInt(),
      tunnel: message.hasTunnel()
          ? NodeTunnel.fromProto(message.tunnel)
          : const NodeTunnel(),
      lastSeenAt: message.hasLastSeenAt()
          ? message.lastSeenAt.toDateTime().toLocal()
          : null,
      gpuName: hardware?.gpuName ?? '',
      vramGb: hardware?.vramGb ?? 0,
      ramGb: hardware?.ramGb ?? 0,
    );
  }
}

/// What a freshly added node still needs before it can be used.
class NodeAddResult {
  final StudioNode node;
  final List<String> nextSteps;

  const NodeAddResult({required this.node, this.nextSteps = const []});
}

/// The tunnel plus the config file itself, for the screen that shows it.
class NodeTunnelDetail {
  final NodeTunnel tunnel;
  final String configText;

  const NodeTunnelDetail({required this.tunnel, this.configText = ''});
}

NodeState _nodeStateFromProto(nodepb.NodeState state) {
  switch (state) {
    case nodepb.NodeState.NODE_STATE_ONLINE:
      return NodeState.online;
    case nodepb.NodeState.NODE_STATE_OFFLINE:
      return NodeState.offline;
    case nodepb.NodeState.NODE_STATE_UNAUTHORIZED:
      return NodeState.unauthorized;
    case nodepb.NodeState.NODE_STATE_DISABLED:
      return NodeState.disabled;
    default:
      return NodeState.unknown;
  }
}

NodeTunnelState _tunnelStateFromProto(nodepb.TunnelState state) {
  switch (state) {
    case nodepb.TunnelState.TUNNEL_STATE_UP:
      return NodeTunnelState.up;
    case nodepb.TunnelState.TUNNEL_STATE_DOWN:
      return NodeTunnelState.down;
    case nodepb.TunnelState.TUNNEL_STATE_UNAVAILABLE:
      return NodeTunnelState.unavailable;
    default:
      return NodeTunnelState.unknown;
  }
}

/// The nodes this Studio knows about.
///
/// Errors are thrown rather than folded into the result: adding a node is a
/// deliberate act with a message worth reading, unlike the polling calls
/// elsewhere that quietly return an error map.
class NodeApi {
  final ApiClient _client;

  NodeApi(this._client);

  Future<List<StudioNode>> listNodes() async {
    try {
      final response = await _client.nodeClient.listNodes(
        nodepb.ListNodesRequest(),
      );
      return response.nodes.map(StudioNode.fromProto).toList();
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }

  /// Registers a node from the join code its node mode printed.
  Future<NodeAddResult> addNodeFromJoinCode(
    String joinCode, {
    String name = '',
  }) async {
    try {
      final response = await _client.nodeClient.addNode(
        nodepb.AddNodeRequest(joinCode: joinCode.trim(), name: name.trim()),
      );
      return NodeAddResult(
        node: StudioNode.fromProto(response.node),
        nextSteps: response.nextSteps.toList(),
      );
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }

  /// Registers a node whose tunnel was set up outside the Studio.
  Future<NodeAddResult> addNodeManually({
    required String name,
    required String address,
    required String token,
    int grpcPort = 50051,
    int gatewayPort = 8091,
  }) async {
    try {
      final response = await _client.nodeClient.addNode(
        nodepb.AddNodeRequest(
          manual: nodepb.ManualNodeDetails(
            name: name.trim(),
            address: address.trim(),
            token: token.trim(),
            grpcPort: grpcPort,
            gatewayPort: gatewayPort,
          ),
        ),
      );
      return NodeAddResult(
        node: StudioNode.fromProto(response.node),
        nextSteps: response.nextSteps.toList(),
      );
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }

  Future<StudioNode> updateNode(
    String nodeId, {
    String? name,
    bool? enabled,
  }) async {
    try {
      final request = nodepb.UpdateNodeRequest(nodeId: nodeId);
      if (name != null) request.name = name.trim();
      if (enabled != null) request.enabled = enabled;
      final response = await _client.nodeClient.updateNode(request);
      return StudioNode.fromProto(response.node);
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }

  Future<void> removeNode(String nodeId, {bool deleteTunnelConfig = true}) async {
    try {
      await _client.nodeClient.removeNode(
        nodepb.RemoveNodeRequest(
          nodeId: nodeId,
          deleteTunnelConfig: deleteTunnelConfig,
        ),
      );
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }

  /// Probes one node, or every enabled one when [nodeId] is empty.
  Future<List<StudioNode>> refreshNodes({String nodeId = ''}) async {
    try {
      final response = await _client.nodeClient.refreshNode(
        nodepb.RefreshNodeRequest(nodeId: nodeId),
      );
      return response.nodes.map(StudioNode.fromProto).toList();
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }

  Future<NodeTunnelDetail> getTunnel(String nodeId) async {
    try {
      final response = await _client.nodeClient.getNodeTunnel(
        nodepb.GetNodeTunnelRequest(nodeId: nodeId),
      );
      return NodeTunnelDetail(
        tunnel: NodeTunnel.fromProto(response.tunnel),
        configText: response.configText,
      );
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }

  /// Brings the interface up or down. This is the call that needs the
  /// privilege prompt, so it is the one that fails with a command to run by
  /// hand when there is nothing on the system that can ask for rights.
  Future<NodeTunnel> setTunnel(String nodeId, {required bool up}) async {
    try {
      final response = await _client.nodeClient.setNodeTunnel(
        nodepb.SetNodeTunnelRequest(nodeId: nodeId, up: up),
      );
      return NodeTunnel.fromProto(response.tunnel);
    } catch (error) {
      throw ApiException(_client.grpcErrorMessage(error));
    }
  }
}
