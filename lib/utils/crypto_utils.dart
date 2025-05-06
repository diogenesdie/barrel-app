import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:convert/convert.dart';

String encryptData(String keyHex, String ivHex, Map<String, dynamic> data) {
  // Converter a chave e o IV de hexadecimal para bytes
  final key = Key(Uint8List.fromList(hex.decode(keyHex)));
  final iv = IV(Uint8List.fromList(hex.decode(ivHex)));

  // Criar o encriptador AES-CBC
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

  // Converter o JSON para string
  final jsonString = jsonEncode(data);

  // Criptografar e codificar em base64
  final encrypted = encrypter.encrypt(jsonString, iv: iv);
  
  return encrypted.base64;
}
