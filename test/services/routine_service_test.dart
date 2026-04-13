// =============================================================================
// routine_service_test.dart
//
// Testes unitários para RoutineService — chamadas HTTP de CRUD e execução.
// =============================================================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_home/models/routine.dart';
import 'package:smart_home/services/routine_service.dart';

http.Response _jsonResponse(int status, Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), status,
      headers: {'content-type': 'application/json'});
}

RoutineService _makeService(MockClient client) =>
    RoutineService(baseUrl: 'http://test', client: client);

final _routineJson = {
  'id': 1,
  'user_id': 1,
  'name': 'Rotina Manhã',
  'enabled': true,
  'trigger': {'type': 'schedule', 'cron': '0 7 * * *'},
  'actions': [],
  'created_at': '2026-04-12T00:00:00Z',
  'updated_at': '2026-04-12T00:00:00Z',
};

final _routine = Routine(
  id: 0,
  userId: 1,
  name: 'Rotina Manhã',
  enabled: true,
  trigger: RoutineTrigger(type: 'schedule', cron: '0 7 * * *'),
  actions: [],
);

void main() {
  group('RoutineService.listRoutines', () {
    test('returns list on 200', () async {
      final client = MockClient((_) async =>
          _jsonResponse(200, {'data': [_routineJson]}));
      final routines = await _makeService(client).listRoutines();
      expect(routines.length, 1);
      expect(routines.first.name, 'Rotina Manhã');
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 401));
      expect(() => _makeService(client).listRoutines(), throwsException);
    });
  });

  group('RoutineService.createRoutine', () {
    test('returns created routine on 201', () async {
      final client = MockClient((_) async =>
          _jsonResponse(201, {'data': {..._routineJson, 'id': 7}}));
      final created = await _makeService(client).createRoutine(_routine);
      expect(created.id, 7);
    });

    test('throws on non-201', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      expect(() => _makeService(client).createRoutine(_routine), throwsException);
    });
  });

  group('RoutineService.updateRoutine', () {
    test('returns updated routine on 200', () async {
      final updated = {..._routineJson, 'id': 1, 'name': 'Editada'};
      final client = MockClient((_) async =>
          _jsonResponse(200, {'data': updated}));
      final r = await _makeService(client)
          .updateRoutine(_routine.copyWith(id: 1));
      expect(r.name, 'Editada');
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 404));
      expect(() => _makeService(client).updateRoutine(_routine.copyWith(id: 1)),
          throwsException);
    });
  });

  group('RoutineService.deleteRoutine', () {
    test('completes on 200', () async {
      final client = MockClient((_) async =>
          _jsonResponse(200, {'message': 'ok'}));
      await expectLater(_makeService(client).deleteRoutine(1), completes);
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 404));
      expect(() => _makeService(client).deleteRoutine(1), throwsException);
    });
  });

  group('RoutineService.executeRoutine', () {
    test('completes on 200', () async {
      final client = MockClient((_) async =>
          _jsonResponse(200, {'message': 'executed'}));
      await expectLater(_makeService(client).executeRoutine(1), completes);
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      expect(() => _makeService(client).executeRoutine(1), throwsException);
    });
  });

  group('RoutineService.toggleRoutine', () {
    test('returns updated routine on 200', () async {
      final updated = {..._routineJson, 'enabled': false};
      final client = MockClient((_) async =>
          _jsonResponse(200, {'data': updated}));
      final r = await _makeService(client).toggleRoutine(1, enabled: false);
      expect(r.enabled, false);
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      expect(() => _makeService(client).toggleRoutine(1, enabled: false),
          throwsException);
    });
  });
}
