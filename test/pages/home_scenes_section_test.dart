// =============================================================================
// home_scenes_section_test.dart
//
// Testes de widget para ScenesSectionWidget — seção de Cenas na home screen.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_home/components/scenes_section.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Configura mock para FlutterSecureStorage (retorna null para todas as chamadas).
void _setupSecureStorageMock() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async => null);
}

http.Response _jsonResponse(int status, Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), status,
      headers: {'content-type': 'application/json'});
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

final _twoScenes = [
  {
    'id': 1,
    'user_id': 1,
    'name': 'Modo Cinema',
    'icon': 'movie',
    'actions': [],
    'created_at': '2026-04-12T00:00:00Z',
    'updated_at': '2026-04-12T00:00:00Z',
  },
  {
    'id': 2,
    'user_id': 1,
    'name': 'Modo Dormir',
    'icon': 'bed',
    'actions': [],
    'created_at': '2026-04-12T00:00:00Z',
    'updated_at': '2026-04-12T00:00:00Z',
  },
];

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  setUp(_setupSecureStorageMock);

  group('ScenesSectionWidget — renderização da lista', () {
    testWidgets('exibe o cabeçalho "Cenas"', (tester) async {
      final client = MockClient((_) async => _jsonResponse(200, {'data': []}));

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pump();

      expect(find.text('Cenas'), findsOneWidget);
    });

    testWidgets('exibe indicador de carregamento enquanto carrega', (tester) async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) async => completer.future);

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Conclui o request para não deixar timers pendentes
      completer.complete(_jsonResponse(200, {'data': []}));
      await tester.pumpAndSettle();
    });

    testWidgets('exibe cartões de cena após carregamento', (tester) async {
      final client =
          MockClient((_) async => _jsonResponse(200, {'data': _twoScenes}));

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pumpAndSettle();

      expect(find.text('Modo Cinema'), findsOneWidget);
      expect(find.text('Modo Dormir'), findsOneWidget);
    });

    testWidgets('exibe mensagem de lista vazia quando não há cenas', (tester) async {
      final client = MockClient((_) async => _jsonResponse(200, {'data': []}));

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma cena criada.'), findsOneWidget);
    });
  });

  group('ScenesSectionWidget — botão de execução rápida', () {
    testWidgets('cada cartão de cena possui botão de play', (tester) async {
      final client =
          MockClient((_) async => _jsonResponse(200, {'data': _twoScenes}));

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsNWidgets(2));
    });

    testWidgets('tapping play exibe snackbar de sucesso', (tester) async {
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/execute')) {
          return _jsonResponse(200, {
            'data': {'scene_id': 1, 'actions': []}
          });
        }
        return _jsonResponse(200, {'data': _twoScenes});
      });

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Cena executada!'), findsOneWidget);
    });

    testWidgets('exibe snackbar de erro quando execução falha', (tester) async {
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/execute')) {
          return http.Response('error', 500);
        }
        return _jsonResponse(200, {'data': _twoScenes});
      });

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Erro'), findsOneWidget);
    });
  });

  group('ScenesSectionWidget — estado de erro', () {
    testWidgets('exibe mensagem de erro quando listagem falha', (tester) async {
      final client = MockClient((_) async => http.Response('error', 500));

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro'), findsOneWidget);
    });

    testWidgets('botão Tentar novamente recarrega as cenas', (tester) async {
      int attempt = 0;
      final client = MockClient((_) async {
        attempt++;
        if (attempt == 1) return http.Response('error', 500);
        return _jsonResponse(200, {'data': _twoScenes});
      });

      await tester.pumpWidget(_wrap(ScenesSectionWidget(httpClient: client)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Modo Cinema'), findsOneWidget);
    });
  });
}
