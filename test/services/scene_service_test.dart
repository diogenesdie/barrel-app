import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_home/models/scene.dart';
import 'package:smart_home/services/scene_service.dart';

// Stub de SessionUtils para evitar SharedPreferences em testes
// O SceneService recebe baseUrl e client injetados — token é irrelevante aqui
// pois o MockClient ignora headers.

http.Response _jsonResponse(int status, Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), status,
      headers: {'content-type': 'application/json'});
}

SceneService _makeService(MockClient client) {
  return SceneService(
    baseUrl: 'http://test',
    client: client,
  );
}

void main() {
  group('SceneService.listScenes', () {
    test('returns list on 200', () async {
      final client = MockClient((_) async => _jsonResponse(200, {
            'data': [
              {
                'id': 1,
                'user_id': 1,
                'name': 'Modo Cinema',
                'icon': 'movie',
                'actions': [],
                'created_at': '2026-04-12T00:00:00Z',
                'updated_at': '2026-04-12T00:00:00Z',
              }
            ]
          }));
      final service = _makeService(client);
      final scenes = await service.listScenes();
      expect(scenes.length, 1);
      expect(scenes.first.name, 'Modo Cinema');
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 401));
      final service = _makeService(client);
      expect(() => service.listScenes(), throwsException);
    });
  });

  group('SceneService.createScene', () {
    test('returns created scene on 201', () async {
      final client = MockClient((_) async => _jsonResponse(201, {
            'data': {
              'id': 5,
              'user_id': 1,
              'name': 'Nova Cena',
              'icon': null,
              'actions': [],
              'created_at': '2026-04-12T00:00:00Z',
              'updated_at': '2026-04-12T00:00:00Z',
            }
          }));
      final service = _makeService(client);
      final scene = await service.createScene(
          Scene(id: 0, userId: 1, name: 'Nova Cena'));
      expect(scene.id, 5);
      expect(scene.name, 'Nova Cena');
    });

    test('throws on non-201', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final service = _makeService(client);
      expect(
          () => service.createScene(Scene(id: 0, userId: 1, name: 'X')),
          throwsException);
    });
  });

  group('SceneService.deleteScene', () {
    test('completes on 200', () async {
      final client =
          MockClient((_) async => _jsonResponse(200, {'message': 'ok'}));
      final service = _makeService(client);
      await expectLater(service.deleteScene(1), completes);
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 404));
      final service = _makeService(client);
      expect(() => service.deleteScene(1), throwsException);
    });
  });

  group('SceneService.executeScene', () {
    test('returns result map on 200', () async {
      final client = MockClient((_) async => _jsonResponse(200, {
            'data': {'scene_id': 1, 'actions': []}
          }));
      final service = _makeService(client);
      final result = await service.executeScene(1);
      expect(result, isA<Map<String, dynamic>>());
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final service = _makeService(client);
      expect(() => service.executeScene(1), throwsException);
    });
  });
}
