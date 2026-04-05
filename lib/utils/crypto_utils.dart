// =============================================================================
// crypto_utils.dart
//
// Criptografia AES-CBC para comunicação com firmware dos dispositivos Barrel.
// A chave e o IV são armazenados em Device.ivKey no formato "keyHex:ivHex".
// O resultado é codificado em Base64 e enviado ao firmware via HTTP ou MQTT.
// =============================================================================

// Dart SDK
import 'dart:typed_data';

// Terceiros
import 'package:convert/convert.dart';
import 'package:encrypt/encrypt.dart';

/// Criptografa [data] usando AES-CBC com a [keyHex] e o [ivHex] fornecidos em hexadecimal.
///
/// Retorna o texto cifrado codificado em Base64.
/// Uso: `encryptData(device.ivKey.split(':')[0], device.ivKey.split(':')[1], command)`
String encryptData(String keyHex, String ivHex, String data) {
  // Converter a chave e o IV de hexadecimal para bytes
  final key = Key(Uint8List.fromList(hex.decode(keyHex)));
  final iv = IV(Uint8List.fromList(hex.decode(ivHex)));

  // Criar o encriptador AES-CBC
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

  // Criptografar e codificar em base64
  final encrypted = encrypter.encrypt(data, iv: iv);

  return encrypted.base64;
}
