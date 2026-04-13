// =============================================================================
// routine_detail_page_test.dart
//
// Testes de widget para RoutineDetailPage — criação e edição de rotinas.
// Fase Red (TDD): testes escritos antes da implementação do widget.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_home/models/routine.dart';
import 'package:smart_home/models/scene.dart';
import 'package:smart_home/pages/routine_detail_page.dart';
import 'package:smart_home/services/routine_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _setupSecureStorageMock() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async => null);
}

http.Response _jsonResponse(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

final _devicesPayload = {
  'data': [
    {'id': 10, 'name': 'Lâmpada Sala'},
    {'id': 11, 'name': 'Tomada Cozinha'},
  ]
};

final _scenesPayload = {
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
};

Map<String, dynamic> _createdRoutinePayload(String name) => {
      'data': {
        'id': 99,
        'user_id': 1,
        'name': name,
        'enabled': true,
        'trigger': {'type': 'schedule', 'cron': '0 8 * * *'},
        'actions': [],
        'created_at': '2026-04-12T00:00:00Z',
        'updated_at': '2026-04-12T00:00:00Z',
      }
    };

/// MockClient que responde a /devices, /scenes e POST /routines
MockClient _defaultClient({String? overrideMethod, int overrideStatus = 201}) {
  return MockClient((req) async {
    if (req.url.path.endsWith('/devices')) {
      return _jsonResponse(200, _devicesPayload);
    }
    if (req.url.path.endsWith('/scenes')) {
      return _jsonResponse(200, _scenesPayload);
    }
    if (overrideMethod != null && req.method == overrideMethod) {
      return http.Response('error', overrideStatus);
    }
    if (req.method == 'POST') {
      return _jsonResponse(201, _createdRoutinePayload('Nova Rotina'));
    }
    return http.Response('not found', 404);
  });
}

final _existingRoutine = Routine(
  id: 10,
  userId: 1,
  name: 'Rotina Manhã',
  enabled: true,
  trigger: RoutineTrigger(type: 'schedule', cron: '0 7 * * *'),
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
  // Seleção de tipo de gatilho
  // -------------------------------------------------------------------------
  group('RoutineDetailPage — seleção de gatilho', () {
    testWidgets('exibe título "Nova Rotina" ao criar', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      expect(find.text('Nova Rotina'), findsOneWidget);
    });

    testWidgets('exibe título "Editar Rotina" ao editar', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(
          routine: _existingRoutine,
          service: RoutineService(client: client),
          httpClient: client,
        ),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      expect(find.text('Editar Rotina'), findsOneWidget);
    });

    testWidgets('campo de nome preenchido ao editar', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(
          routine: _existingRoutine,
          service: RoutineService(client: client),
          httpClient: client,
        ),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('routine_name_field'));
      expect(tester.widget<TextFormField>(field).controller?.text, 'Rotina Manhã');
    });

    testWidgets('exibe opções de tipo de gatilho: Dispositivo e Agendamento',
        (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      completer.complete(_jsonResponse(200, _devicesPayload));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trigger_device')), findsOneWidget);
      expect(find.byKey(const Key('trigger_schedule')), findsOneWidget);
    });

    testWidgets('selecionar "Dispositivo" exibe seletor de dispositivo',
        (tester) async {
      final client = _defaultClient();

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trigger_device')));
      await tester.pump();

      expect(find.byKey(const Key('trigger_device_picker')), findsOneWidget);
    });

    testWidgets('selecionar "Agendamento" exibe campo de cron', (tester) async {
      final client = _defaultClient();

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trigger_schedule')));
      await tester.pump();

      expect(find.byKey(const Key('trigger_cron_field')), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Ações
  // -------------------------------------------------------------------------
  group('RoutineDetailPage — ações', () {
    testWidgets('exibe mensagem de nenhuma ação inicialmente', (tester) async {
      final client = _defaultClient();

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma ação adicionada.'), findsOneWidget);
    });

    testWidgets('adiciona ação de dispositivo', (tester) async {
      final client = _defaultClient();

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_device_action_button')));
      await tester.pump();

      expect(find.byKey(const Key('action_device_picker_0')), findsOneWidget);
    });

    testWidgets('adiciona ação de cena', (tester) async {
      final client = _defaultClient();

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_scene_action_button')));
      await tester.pump();

      expect(find.byKey(const Key('action_scene_picker_0')), findsOneWidget);
    });

    testWidgets('remove ação ao tocar no X', (tester) async {
      final client = _defaultClient();

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_device_action_button')));
      await tester.pump();

      expect(find.byKey(const Key('action_device_picker_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('remove_action_0')));
      await tester.pump();

      expect(find.byKey(const Key('action_device_picker_0')), findsNothing);
      expect(find.text('Nenhuma ação adicionada.'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Salvar
  // -------------------------------------------------------------------------
  group('RoutineDetailPage — salvar', () {
    testWidgets('valida campo de nome obrigatório', (tester) async {
      final client = _defaultClient();

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Nome obrigatório'), findsOneWidget);
    });

    testWidgets('criação bem-sucedida faz pop com true', (tester) async {
      bool? popResult;
      final client = _defaultClient();

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              popResult = await Navigator.push<bool>(
                ctx,
                MaterialPageRoute(
                  builder: (_) => RoutineDetailPage(
                    service: RoutineService(client: client),
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

      await tester.enterText(
          find.byKey(const Key('routine_name_field')), 'Nova Rotina');

      // Seleciona gatilho Agendamento e preenche cron
      await tester.tap(find.byKey(const Key('trigger_schedule')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('trigger_cron_field')), '0 8 * * *');

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(popResult, true);
    });

    testWidgets('erro ao salvar exibe snackbar', (tester) async {
      final client = _defaultClient(overrideMethod: 'POST', overrideStatus: 500);

      await tester.pumpWidget(_wrap(
        RoutineDetailPage(service: RoutineService(client: client), httpClient: client),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('routine_name_field')), 'Rotina X');
      await tester.tap(find.byKey(const Key('trigger_schedule')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('trigger_cron_field')), '0 8 * * *');

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Erro'), findsOneWidget);
    });
  });
}
