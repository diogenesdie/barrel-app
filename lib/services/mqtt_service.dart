// =============================================================================
// mqtt_service.dart
//
// Serviço MQTT singleton para comunicação em tempo real com dispositivos.
//
// Broker:  barrel.app.br:1883
// Tópicos:
//   - Comando:  users/<owner_username>/<deviceId>/command
//   - Status:   users/<owner_username>/<deviceId>/status
//
// Funcionalidades:
//   - Conexão autenticada com as credenciais do usuário logado
//   - Publicação de comandos com reconexão automática (até 3 tentativas)
//   - Inscrição em atualizações de estado de dispositivos
// =============================================================================

// Terceiros — MQTT
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// Projeto — core e modelos
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/device_repository.dart';

// Projeto — utils
import 'package:smart_home/utils/session_utils.dart';

/// Singleton que gerencia a conexão MQTT com o broker Barrel.
///
/// Instanciado uma única vez durante o ciclo de vida do app via factory.
/// Use [connect] para autenticar, [publishMessage] para enviar comandos
/// e [subscribe]/[listen] para receber atualizações de estado.
class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;

  late MqttServerClient client;
  bool _connected = false;

  /// Endereço do broker MQTT.
  String broker = 'barrel.app.br';

  String? _username;
  String? _password;
  String? _clientId;

  MqttService._internal() {
    client = MqttServerClient(broker, '');
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.onConnected = () {
      _connected = true;
      print('✅ Conectado ao MQTT');
    };
    client.onDisconnected = () {
      _connected = false;
      print('❌ Desconectado do MQTT');
    };
  }

  /// Estabelece conexão com o broker usando as credenciais do usuário logado.
  /// Se já estiver conectado, retorna imediatamente.
  Future<void> connect({
    required String clientId,
  }) async {
    _clientId = clientId;
    _username = await SessionUtils.getUsername();
    _password = await SessionUtils.getPassword();

    if (_connected) return;

    client.clientIdentifier = clientId;

    final connMessage = MqttConnectMessage().withClientIdentifier(clientId).startClean().withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect(_username, _password);
    } catch (e) {
      print('⚠️ Erro de conexão: $e');
      disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      _connected = true;
      print('MQTT conectado com sucesso!');
    } else {
      print('Falha na conexão: ${client.connectionStatus}');
      disconnect();
    }
  }

  /// Desconecta do broker MQTT e reseta o estado de conexão.
  void disconnect() {
    if (_connected) {
      client.disconnect();
    }
    _connected = false;
  }

  /// Publica [message] no tópico de comando do dispositivo identificado por [id].
  /// Tenta reconectar até 3 vezes antes de falhar. Retorna true se enviado com sucesso.
  Future<bool> publishMessage(int id, String deviceId, String message) async {
    Device? device = await DeviceRepository(apiBaseUrl: BASE_API_URL).getDeviceById(id);
    final username = device?.owner_username;

    if (username == null) {
      print("🚨 Usuário não autenticado");
      return false;
    }

    final topic = "users/$username/$deviceId/command";

    for (int attempt = 1; attempt <= 3; attempt++) {
      if (!_connected) {
        print("⚠️ Não conectado, tentando reconectar ($attempt/3)...");
        await connect(
          clientId: _clientId ?? "flutter_${DateTime.now().millisecondsSinceEpoch}",
        );
      }

      if (_connected) {
        try {
          final builder = MqttClientPayloadBuilder();
          builder.addUTF8String(message);

          client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
          print("📡 Enviado: $message → $topic (tentativa $attempt)");
          return true;
        } catch (e) {
          print("❌ Erro ao publicar (tentativa $attempt): $e");
        }
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    print("🚨 Falha ao enviar mensagem após 3 tentativas");
    return false;
  }

  /// Inscreve-se no tópico de status do dispositivo para receber atualizações de estado.
  void subscribe(int id, String deviceId) async {
    try {
      Device? device = await DeviceRepository(apiBaseUrl: BASE_API_URL).getDeviceById(id);
      final username = device?.owner_username;

      if (username == null) {
        print("🚨 Usuário não autenticado");
        return;
      }

      final topic = "users/$username/$deviceId/status";
      print("🔔 Inscrevendo em: $topic");
      client.subscribe(topic, MqttQos.atLeastOnce);

    } catch (e) {
      print("❌ Erro ao inscrever: $e");
    }
  }

  /// Registra um callback chamado a cada mensagem MQTT recebida nos tópicos inscritos.
  void listen(void Function(String topic, String payload) onMessage) {
    client.updates?.listen((events) {
      final recMess = events.first.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      onMessage(events.first.topic, payload);
    });
  }
}
