import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/models/scene.dart';

void main() {
  group('SceneAction', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'scene_id': 2,
        'device_id': 10,
        'command': 'off',
        'sort_order': 1,
      };
      final action = SceneAction.fromJson(json);
      expect(action.id, 1);
      expect(action.sceneId, 2);
      expect(action.deviceId, 10);
      expect(action.command, 'off');
      expect(action.sortOrder, 1);
    });

    test('toJson serializes correctly', () {
      final action = SceneAction(
        id: 0,
        sceneId: 0,
        deviceId: 5,
        command: 'on',
        sortOrder: 2,
      );
      final json = action.toJson();
      expect(json['device_id'], 5);
      expect(json['command'], 'on');
      expect(json['sort_order'], 2);
    });
  });

  group('Scene', () {
    test('fromJson parses correctly with actions', () {
      final json = {
        'id': 1,
        'user_id': 42,
        'name': 'Modo Cinema',
        'icon': 'movie',
        'actions': [
          {'id': 1, 'scene_id': 1, 'device_id': 10, 'command': 'off', 'sort_order': 1},
          {'id': 2, 'scene_id': 1, 'device_id': 20, 'command': 'on', 'sort_order': 2},
        ],
        'created_at': '2026-04-12T00:00:00Z',
        'updated_at': '2026-04-12T00:00:00Z',
      };
      final scene = Scene.fromJson(json);
      expect(scene.id, 1);
      expect(scene.name, 'Modo Cinema');
      expect(scene.icon, 'movie');
      expect(scene.actions.length, 2);
      expect(scene.actions.first.command, 'off');
    });

    test('fromJson handles null icon', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'name': 'Cena',
        'icon': null,
        'actions': [],
        'created_at': '2026-04-12T00:00:00Z',
        'updated_at': '2026-04-12T00:00:00Z',
      };
      final scene = Scene.fromJson(json);
      expect(scene.icon, isNull);
    });

    test('toJson serializes correctly', () {
      final scene = Scene(
        id: 0,
        userId: 1,
        name: 'Cena Teste',
        icon: null,
        actions: [
          SceneAction(id: 0, sceneId: 0, deviceId: 5, command: 'on', sortOrder: 1),
        ],
      );
      final json = scene.toJson();
      expect(json['name'], 'Cena Teste');
      expect((json['actions'] as List).length, 1);
    });

    test('fromJson round-trips via toJson', () {
      final original = Scene(
        id: 7,
        userId: 3,
        name: 'Cena Round-trip',
        icon: 'home',
        actions: [],
      );
      final json = original.toJson();
      json['created_at'] = '2026-04-12T00:00:00Z';
      json['updated_at'] = '2026-04-12T00:00:00Z';
      final restored = Scene.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
    });
  });
}
