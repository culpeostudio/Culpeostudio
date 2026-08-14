import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';

import 'package:culpeo_studio/core/app_strings.dart';
import 'package:culpeo_studio/generated/culpeostudio/hardware/v1/hardware.pb.dart'
    as hardwarepb;
import 'package:culpeo_studio/generated/culpeostudio/node/v1/node.pb.dart'
    as nodepb;
import 'package:culpeo_studio/generated/culpeostudio/node/v1/node.pbenum.dart'
    as nodeenum;
import 'package:culpeo_studio/modules/engine/models.dart';
import 'package:culpeo_studio/modules/nodes/node_api.dart';
import 'package:culpeo_studio/modules/nodes/node_format.dart';
import 'package:culpeo_studio/modules/nodes/node_target_picker.dart';

nodepb.Node _protoNode({
  String id = 'nodeone',
  String name = 'Werkstatt',
  bool enabled = true,
  nodeenum.NodeState state = nodeenum.NodeState.NODE_STATE_ONLINE,
}) {
  return nodepb.Node(
    id: id,
    name: name,
    address: '10.77.0.1',
    grpcPort: 50051,
    gatewayPort: 8091,
    enabled: enabled,
    state: state,
    modelCount: 4,
    instanceCount: 1,
    diskFreeBytes: Int64(64 * 1024 * 1024 * 1024),
    hardware: hardwarepb.HardwareProfile(gpuName: 'RTX 4090', vramGb: 24),
    tunnel: nodepb.NodeTunnel(
      interfaceName: 'culpeo-nodeone',
      configPath: '/home/x/data/wireguard/culpeo-nodeone.conf',
      localAddress: '10.77.0.2/32',
      endpoint: 'node.example.org:51820',
      state: nodeenum.TunnelState.TUNNEL_STATE_UP,
    ),
  );
}

void main() {
  setUp(() => appLanguage = 'de');

  group('StudioNode', () {
    test('reads what the backend reported', () {
      final node = StudioNode.fromProto(_protoNode());

      expect(node.id, 'nodeone');
      expect(node.name, 'Werkstatt');
      expect(node.state, NodeState.online);
      expect(node.modelCount, 4);
      expect(node.diskFreeBytes, 64 * 1024 * 1024 * 1024);
      expect(node.gpuName, 'RTX 4090');
      expect(node.vramGb, 24);
      expect(node.tunnel.state, NodeTunnelState.up);
      expect(node.tunnel.isManaged, isTrue);
    });

    test('is only usable when it is switched on and answering', () {
      expect(StudioNode.fromProto(_protoNode()).isUsable, isTrue);
      expect(
        StudioNode.fromProto(
          _protoNode(
            enabled: false,
            state: nodeenum.NodeState.NODE_STATE_DISABLED,
          ),
        ).isUsable,
        isFalse,
      );
      expect(
        StudioNode.fromProto(
          _protoNode(state: nodeenum.NodeState.NODE_STATE_OFFLINE),
        ).isUsable,
        isFalse,
      );
    });

    test('a tunnel nobody wrote here is reported as managed elsewhere', () {
      final node = StudioNode.fromProto(
        _protoNode()..tunnel = nodepb.NodeTunnel(),
      );
      expect(node.tunnel.isManaged, isFalse);
      expect(
        tunnelStateLabel(node.tunnel.state, node.tunnel.isManaged),
        tr('nodes.tunnel.unknown'),
      );
    });
  });

  group('engine records', () {
    test('a model on a node says so', () {
      final model = ModelRecord.fromJson({
        'id': 'n:nodeone:org/model',
        'name': 'Qwen3',
        'node_id': 'nodeone',
        'node_name': 'Werkstatt',
        'status': 'ready',
      });
      expect(model.isOnNode, isTrue);
      expect(model.nodeName, 'Werkstatt');
    });

    test('a local model carries no node', () {
      final model = ModelRecord.fromJson({'id': 'org/model', 'name': 'Qwen3'});
      expect(model.isOnNode, isFalse);
      expect(model.nodeId, isEmpty);
    });

    test('an instance on a node keeps its qualified id', () {
      final instance = EngineInstance.fromJson({
        'id': 'n:nodeone:inst-1',
        'model_id': 'n:nodeone:org/model',
        'state': 'ready',
        'node_id': 'nodeone',
        'node_name': 'Werkstatt',
      });
      expect(instance.isOnNode, isTrue);
      // The id has to survive intact: it is what routes the next call.
      expect(instance.id, 'n:nodeone:inst-1');
      expect(instance.nodeName, 'Werkstatt');
    });
  });

  group('download target picker', () {
    testWidgets('offers this machine and every usable node', (tester) async {
      final nodes = [
        StudioNode.fromProto(_protoNode(id: 'one', name: 'Werkstatt')),
        StudioNode.fromProto(
          _protoNode(
            id: 'two',
            name: 'Keller',
            state: nodeenum.NodeState.NODE_STATE_OFFLINE,
          ),
        ),
      ];
      NodeDownloadTarget? picked;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked = await showNodeTargetPicker(context, nodes);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(tr('nodes.target.local')), findsOneWidget);
      expect(find.text('Werkstatt'), findsOneWidget);
      // An unreachable node is still listed, so its absence is not mistaken
      // for a node that was never added - it just cannot be chosen.
      expect(find.text('Keller'), findsOneWidget);

      await tester.tap(find.text('Keller'));
      await tester.pumpAndSettle();
      expect(picked, isNull, reason: 'an offline node must not be selectable');

      await tester.tap(find.text('Werkstatt'));
      await tester.pumpAndSettle();
      expect(picked?.nodeId, 'one');
      expect(picked?.isLocal, isFalse);
    });

    testWidgets('picking this machine yields an empty node id', (tester) async {
      NodeDownloadTarget? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked = await showNodeTargetPicker(context, [
                  StudioNode.fromProto(_protoNode()),
                ]);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr('nodes.target.local')));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.isLocal, isTrue);
      expect(picked!.nodeId, isEmpty);
    });
  });

  group('formatting', () {
    test('bytes read as the sizes a disk is talked about in', () {
      expect(formatNodeBytes(0), '–');
      expect(formatNodeBytes(64 * 1024 * 1024 * 1024), '64.0 GB');
      expect(formatNodeBytes(512 * 1024 * 1024), '512 MB');
    });

    test('every node state has a label in both languages', () {
      for (final language in ['de', 'en']) {
        appLanguage = language;
        for (final state in NodeState.values) {
          final label = nodeStateLabel(state);
          expect(label, isNotEmpty);
          expect(
            label.startsWith('nodes.'),
            isFalse,
            reason: '$state has no $language translation',
          );
        }
      }
    });
  });
}
