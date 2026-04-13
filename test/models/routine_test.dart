// =============================================================================
// routine_test.dart
//
// Testes de serialização/deserialização do modelo Routine.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/models/routine.dart';

void main() {
  group('RoutineTrigger fromJson / toJson', () {
    test('device trigger parses correctly', () {
      final json = {
        'type': 'device',
        'device_id': 5,
        'expected_state': {'state': 'on'},
      };
      final t = RoutineTrigger.fromJson(json);
      expect(t.type, 'device');
      expect(t.deviceId, 5);
      expect(t.expectedState, {'state': 'on'});
      expect(t.cron, isNull);
    });

    test('schedule trigger parses correctly', () {
      final json = {'type': 'schedule', 'cron': '0 8 * * *'};
      final t = RoutineTrigger.fromJson(json);
      expect(t.type, 'schedule');
      expect(t.cron, '0 8 * * *');
      expect(t.deviceId, isNull);
    });

    test('toJson round-trips device trigger', () {
      final t = RoutineTrigger(
        type: 'device',
        deviceId: 3,
        expectedState: {'state': 'off'},
      );
      final json = t.toJson();
      expect(json['type'], 'device');
      expect(json['device_id'], 3);
      expect(json['expected_state'], {'state': 'off'});
      expect(json.containsKey('cron'), isFalse);
    });

    test('toJson round-trips schedule trigger', () {
      final t = RoutineTrigger(type: 'schedule', cron: '0 22 * * 1-5');
      final json = t.toJson();
      expect(json['type'], 'schedule');
      expect(json['cron'], '0 22 * * 1-5');
      expect(json.containsKey('device_id'), isFalse);
    });
  });

  group('RoutineAction fromJson / toJson', () {
    test('device action parses correctly', () {
      final json = {
        'id': 1,
        'routine_id': 10,
        'type': 'device',
        'device_id': 7,
        'command': 'on',
        'sort_order': 1,
        'created_at': '2026-04-12T00:00:00Z',
      };
      final a = RoutineAction.fromJson(json);
      expect(a.id, 1);
      expect(a.type, 'device');
      expect(a.deviceId, 7);
      expect(a.command, 'on');
      expect(a.sceneId, isNull);
    });

    test('scene action parses correctly', () {
      final json = {
        'id': 2,
        'routine_id': 10,
        'type': 'scene',
        'scene_id': 42,
        'sort_order': 2,
        'created_at': '2026-04-12T00:00:00Z',
      };
      final a = RoutineAction.fromJson(json);
      expect(a.type, 'scene');
      expect(a.sceneId, 42);
      expect(a.deviceId, isNull);
    });

    test('toJson round-trips device action', () {
      final a = RoutineAction(
        id: 0,
        routineId: 0,
        type: 'device',
        deviceId: 5,
        command: 'off',
        sortOrder: 1,
      );
      final json = a.toJson();
      expect(json['type'], 'device');
      expect(json['device_id'], 5);
      expect(json['command'], 'off');
    });
  });

  group('Routine fromJson / toJson', () {
    test('parses full routine with device trigger and actions', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'name': 'Rotina Manhã',
        'enabled': true,
        'trigger': {'type': 'schedule', 'cron': '0 7 * * *'},
        'actions': [
          {
            'id': 1,
            'routine_id': 1,
            'type': 'device',
            'device_id': 3,
            'command': 'on',
            'sort_order': 1,
            'created_at': '2026-04-12T00:00:00Z',
          }
        ],
        'created_at': '2026-04-12T00:00:00Z',
        'updated_at': '2026-04-12T00:00:00Z',
      };
      final r = Routine.fromJson(json);
      expect(r.id, 1);
      expect(r.name, 'Rotina Manhã');
      expect(r.enabled, true);
      expect(r.trigger.type, 'schedule');
      expect(r.actions.length, 1);
      expect(r.actions.first.command, 'on');
    });

    test('handles empty actions list', () {
      final json = {
        'id': 2,
        'user_id': 1,
        'name': 'Sem ações',
        'enabled': false,
        'trigger': {'type': 'device', 'device_id': 1, 'expected_state': {'state': 'on'}},
        'actions': [],
        'created_at': '2026-04-12T00:00:00Z',
        'updated_at': '2026-04-12T00:00:00Z',
      };
      final r = Routine.fromJson(json);
      expect(r.enabled, false);
      expect(r.actions, isEmpty);
    });

    test('toJson round-trips', () {
      final r = Routine(
        id: 0,
        userId: 0,
        name: 'Nova Rotina',
        enabled: true,
        trigger: RoutineTrigger(type: 'schedule', cron: '0 9 * * *'),
        actions: [],
      );
      final json = r.toJson();
      expect(json['name'], 'Nova Rotina');
      expect(json['enabled'], true);
      expect((json['trigger'] as Map)['cron'], '0 9 * * *');
    });
  });
}
