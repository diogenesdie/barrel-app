// =============================================================================
// scene_detail_page_test.dart
//
// Testes de widget para SceneDetailPage — criação e edição de cenas.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_home/models/scene.dart';
import 'package:smart_home/pages/scene_detail_page.dart';
import 'package:smart_home/services/scene_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _setupSecureStorageMock() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async => null);
}

http.Response _jsonResponse(int status, Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), status,
      headers: {'content-type': 'application/json'});
}

/// Devices list retornada pelo endpoint /devices
final _devicesPayload = {
  'data': [
    {'id': 10, 'name': 'Lâmpada Sala'},
    {'id': 11, 'name': 'Tomada Cozinha'},
  ]
};

/// Resposta de criação bem-sucedida
Map<String, dynamic> _createdScenePayload(String name) => {
      'data': {
        'id': 99,
        'user_id': 1,
        'name': name,
        'icon': null,
        'actions': [],
        'created_at': '2026-04-12T00:00:00Z',
        'updated_at': '2026-04-12T00:00:00Z',
      }
    };

/// Resposta de atualização bem-sucedida
Map<String, dynamic> _updatedScenePayload(int id, String name) => {
      'data': {
        'id': id,
        'user_id': 1,
        'name': name,
        'icon': 'movie',
        'actions': [],
        'created_at': '2026-04-12T00:00:00Z',
        'updated_at': '2026-04-12T00:00:00Z',
      }
    };

/// Cena de exemplo para testes de edição
final _existingScene = Scene(
  id: 42,
  userId: 1,
  name: 'Modo Cinema',
  icon: 'movie',
  actions: [],
);

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  setUp(_setupSecureStorageMock);

  // -------------------------------------------------------------------------
  // Formulário de nome e ícone
  // -------------------------------------------------------------------------
  group('SceneDetailPage — formulário de nome e ícone', () {
    testWidgets('exibe título "Nova Cena" ao criar', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(service: SceneService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      expect(find.text('Nova Cena'), findsOneWidget);
    });

    testWidgets('exibe título "Editar Cena" ao editar', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(
          scene: _existingScene,
          service: SceneService(client: client),
        ),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      expect(find.text('Editar Cena'), findsOneWidget);
    });

    testWidgets('preenche nome ao editar cena existente', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(
          scene: _existingScene,
          service: SceneService(client: client),
        ),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('scene_name_field'));
      expect(tester.widget<TextFormField>(field).controller?.text, 'Modo Cinema');
    });

    testWidgets('exibe chips de seleção de ícone', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(service: SceneService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('icon_movie')), findsOneWidget);
      expect(find.byKey(const Key('icon_home')), findsOneWidget);
      expect(find.byKey(const Key('icon_bed')), findsOneWidget);
    });

    testWidgets('valida campo de nome obrigatório', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(service: SceneService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      // Tenta salvar sem preencher o nome
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Nome obrigatório'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Adição e remoção de ações
  // -------------------------------------------------------------------------
  group('SceneDetailPage — ações', () {
    testWidgets('exibe mensagem de nenhuma ação quando lista vazia', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(service: SceneService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma ação adicionada.'), findsOneWidget);
    });

    testWidgets('adiciona ação ao tocar em Adicionar', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(service: SceneService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_action_button')));
      await tester.pump();

      expect(find.byKey(const Key('device_picker_0')), findsOneWidget);
      expect(find.byKey(const Key('command_picker_0')), findsOneWidget);
    });

    testWidgets('remove ação ao tocar no botão X', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        SceneDetailPage(service: SceneService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_action_button')));
      await tester.pump();

      expect(find.byKey(const Key('device_picker_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('remove_action_0')));
      await tester.pump();

      expect(find.byKey(const Key('device_picker_0')), findsNothing);
      expect(find.text('Nenhuma ação adicionada.'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Salvar e cancelar
  // -------------------------------------------------------------------------
  group('SceneDetailPage — salvar e cancelar', () {
    testWidgets('criação bem-sucedida faz pop com true', (tester) async {
      bool? popResult;
      final client = MockClient((req) async {
        if (req.url.path == '/devices') {
          return _jsonResponse(200, _devicesPayload);
        }
        if (req.method == 'POST') {
          return _jsonResponse(201, _createdScenePayload('Nova Cena'));
        }
        return http.Response('not found', 404);
      });

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              popResult = await Navigator.push<bool>(
                ctx,
                MaterialPageRoute(
                  builder: (_) => SceneDetailPage(
                    service: SceneService(client: client),
                    httpClient: client,
                  ),
                ),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('scene_name_field')), 'Nova Cena');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(popResult, true);
    });

    testWidgets('edição bem-sucedida faz pop com true', (tester) async {
      bool? popResult;
      final client = MockClient((req) async {
        if (req.url.path == '/devices') {
          return _jsonResponse(200, _devicesPayload);
        }
        if (req.method == 'PUT') {
          return _jsonResponse(200, _updatedScenePayload(42, 'Modo Cinema'));
        }
        return http.Response('not found', 404);
      });

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              popResult = await Navigator.push<bool>(
                ctx,
                MaterialPageRoute(
                  builder: (_) => SceneDetailPage(
                    scene: _existingScene,
                    service: SceneService(client: client),
                    httpClient: client,
                  ),
                ),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(popResult, true);
    });

    testWidgets('erro ao salvar exibe snackbar', (tester) async {
      final client = MockClient((req) async {
        if (req.url.path == '/devices') {
          return _jsonResponse(200, _devicesPayload);
        }
        return http.Response('server error', 500);
      });

      await tester.pumpWidget(_wrap(
        SceneDetailPage(service: SceneService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('scene_name_field')), 'Cena X');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Erro ao salvar'), findsOneWidget);
    });
  });
}
