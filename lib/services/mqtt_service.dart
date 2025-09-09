import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home/utils/session_utils.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;

  late MqttServerClient client;
  bool _connected = false;

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

  Future<void> connect({
    required String clientId,
    String? username,
    String? password,
  }) async {
    _clientId = clientId;
    _username = username;
    _password = password;

    if (_connected) return;

    client.clientIdentifier = clientId;

    final connMessage = MqttConnectMessage().withClientIdentifier(clientId).startClean().withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect(username, password);
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

  void disconnect() {
    if (_connected) {
      client.disconnect();
    }
    _connected = false;
  }

  Future<bool> publishMessage(String id, String message) async {
    String? username = await SessionUtils.getUsername();

    if (username == null) {
      print("🚨 Usuário não autenticado");
      return false;
    }

    final topic = "users/$username/$id/command";

    for (int attempt = 1; attempt <= 3; attempt++) {
      if (!_connected) {
        print("⚠️ Não conectado, tentando reconectar ($attempt/3)...");
        await connect(
          clientId: _clientId ?? "flutter_${DateTime.now().millisecondsSinceEpoch}",
          username: _username,
          password: _password,
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
}
