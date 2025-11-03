import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'package:smart_home/core/constants.dart';

class ShareDeviceDialog extends StatefulWidget {
  final int? deviceId;
  final int? groupId;

  const ShareDeviceDialog({
    super.key,
    this.deviceId,
    this.groupId,
  }) : assert(
          (deviceId != null && groupId == null) ||
          (deviceId == null && groupId != null),
          'Informe apenas deviceId OU groupId',
        );

  @override
  State<ShareDeviceDialog> createState() => _ShareDeviceDialogState();
}

class _ShareDeviceDialogState extends State<ShareDeviceDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _success = false;
  String? _sharedUserName;
  String? _errorMsg;

  final _codeRegex = RegExp(r'^[A-Z]{3}\d{4}$'); // AAA9999

  /// Implementação REAL da API:
  /// POST {{BASE_API_URL}}/shares
  /// Body: {"code":"AAC0002","device_id":1} ou {"code":"AAC0002","group_id":1}
  /// Sucesso (200/201): {"message":"...","data":{"name":"Nutricionista Teste"},"code":0,"status":201}
  Future<String> _shareByCode(String code) async {
    final token = await SessionUtils.getToken();
    final uri = Uri.parse('$BASE_API_URL/shares');

    final body = <String, dynamic>{
      'code': code,
      if (widget.deviceId != null) 'device_id': widget.deviceId,
      if (widget.groupId != null) 'group_id': widget.groupId,
    };

    http.Response resp;
    try {
      resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
              // Algumas APIs usam esse header personalizado, caso você precise:
              // if (userId != null) 'user_id': userId.toString(),
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Tempo esgotado. Verifique sua conexão.');
    } on http.ClientException catch (e) {
      throw Exception('Erro de rede: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }

    // Trata resposta
    try {
      final data = jsonDecode(resp.body);
      final statusOk = resp.statusCode == 200 || resp.statusCode == 201;

      if (statusOk) {
        final name = (data is Map && data['data'] is Map) ? data['data']['name'] as String? : null;
        if (name == null || name.isEmpty) {
          throw Exception('Resposta sem nome do usuário.');
        }
        return name;
      } else {
        // tenta extrair mensagem amigável do backend
        String msg = 'Falha ao compartilhar (${resp.statusCode}).';
        if (data is Map && data['message'] is String) {
          msg = data['message'];
        } else if (resp.reasonPhrase != null) {
          msg = resp.reasonPhrase!;
        }

        // Tratamento comum de erros
        switch (resp.statusCode) {
          case 400:
            throw Exception(msg); // corpo inválido, device/group ausente, etc.
          case 401:
          case 403:
            throw Exception('Não autorizado. Faça login novamente.');
          case 404:
            throw Exception('Usuário com este código não foi encontrado.');
          case 409:
            throw Exception('Recurso já compartilhado com este usuário.');
          default:
            throw Exception(msg);
        }
      }
    } catch (e) {
      // Caso o body não seja JSON ou parsing falhe
      if (e is Exception) rethrow;
      throw Exception('Falha ao processar resposta do servidor.');
    }
  }

  Future<void> _onConfirm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final name = await _shareByCode(_codeCtrl.text.trim());
      if (!mounted) return;

      setState(() {
        _sharedUserName = name;
        _success = true;
        _isLoading = false;
      });

      // Se quiser fechar automaticamente após o sucesso, descomente:
      // Future.delayed(const Duration(milliseconds: 900), () {
      //   if (mounted) Navigator.pop(context, {'sharedWith': _sharedUserName});
      // });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grad = LinearGradient(
      colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => grad.createShader(bounds),
                child: const Text(
                  "Compartilhar Dispositivo",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                child: _success ? _buildSuccess(context) : _buildForm(context),
              ),

              const SizedBox(height: 16),
              if (_errorMsg != null)
                Text(
                  _errorMsg!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              if (!_success) ...[
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: _isLoading ? null : _onConfirm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Confirmar compartilhamento"),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: () => Navigator.pop(context, {'sharedWith': _sharedUserName}),
                    child: const Text("Fechar"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Insira o código de compartilhamento",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codeCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: InputDecoration(
              hintText: 'Ex.: AAC0002',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              isDense: true,
              suffixIcon: _codeCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() {
                        _codeCtrl.clear();
                        _errorMsg = null;
                      }),
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (_) {
              if (_errorMsg != null) setState(() => _errorMsg = null);
              setState(() {}); // atualiza suffix/validação
            },
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Informe o código.';
              if (!_codeRegex.hasMatch(value)) return 'Formato inválido. Use AAA9999.';
              return null;
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Formato: 3 letras + 4 números (ex.: AAC0002).",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Icon(Icons.check_circle, size: 72, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Text(
          "Compartilhado com",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
          ).createShader(bounds),
          child: Text(
            _sharedUserName ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Converte input para MAIÚSCULAS.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
