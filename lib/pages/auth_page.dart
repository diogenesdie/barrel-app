import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMode { escolha, login, registro, esqueceu }

/// Mesmo gradiente usado no App (primaryColorLight -> primaryColor)
LinearGradient appGradient(BuildContext context) => LinearGradient(
  colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Botão com gradiente reutilizável
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;

  const GradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
    this.borderRadius = 12,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);
    final isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Ink(
        decoration: BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(colors: [
                  Theme.of(context).primaryColorLight.withOpacity(0.5),
                  Theme.of(context).primaryColor.withOpacity(0.5),
                ])
              : grad,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== CONFIG API =====================
const String _kLoginUrl = 'https://barrel.app.br/api/auth/v1/login';
// =====================================================

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _mode = AuthMode.escolha;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ===================== LOGIN INTEGRAÇÃO =====================
  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _emailCtrl.text.trim();
    final password = _senhaCtrl.text;

    setState(() => _loading = true);
    try {
      final resp = await http
          .post(
            Uri.parse(_kLoginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = body['token'] as String?;
        final expiresAt = body['expires_at'] as String?;
        if (token == null || token.isEmpty) {
          _showSnack('Resposta sem token. Tente novamente.', isError: true);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('auth_user', jsonEncode(body));
          if (expiresAt != null) {
            await prefs.setString('auth_expires_at', expiresAt);
          }
          _showSnack('Login realizado com sucesso!');
          await _goHome();
        }
      } else {
        String msg = 'Falha no login (${resp.statusCode}).';
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['message'] is String) {
            msg = data['message'];
          }
        } catch (_) {}
        _showSnack(msg, isError: true);
      }
    } on http.ClientException catch (e) {
      _showSnack('Erro de rede: ${e.message}', isError: true);
    } on TimeoutException {
      _showSnack('Tempo esgotado. Verifique sua conexão.', isError: true);
    } catch (e) {
      _showSnack('Erro inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // ===========================================================

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      ),
    );
  }

  Widget _buildLogo(double maxWidth) {
    final size = maxWidth.clamp(120, 180).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        children: [
          // Troque por Image.asset('assets/logo.png', width: size) se preferir
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FittedBox(
                child: Text(
                  'LOGO',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: suffix,
    );
  }

  String? _validaUsuarioOuEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe usuário ou e-mail';
    if (v.contains('@')) {
      final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
      if (!ok) return 'E-mail inválido';
    }
    return null;
  }

  String? _validaSenha(String? v) {
    if (v == null || v.length < 4) return 'Mínimo 4 caracteres'; // seu backend aceita '1234'
    return null;
  }

  Widget _botoesEscolha(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            onPressed: _loading ? null : () => setState(() => _mode = AuthMode.login),
            child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loading ? null : () => setState(() => _mode = AuthMode.registro),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: ShaderMask(
              shaderCallback: (rect) => appGradient(context).createShader(rect),
              child: const Text(
                'Registrar',
                style: TextStyle(
                  color: Colors.white, // será mascarado
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _loading ? null : _goHome,
            child: const Text('Continuar sem cadastro'),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _loading ? null : () => setState(() => _mode = AuthMode.esqueceu),
          child: Text(
            'Esqueceu sua senha?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _formLogin() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email ou usuário'),
            validator: _validaUsuarioOuEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _senhaCtrl,
            autofillHints: const [AutofillHints.password],
            obscureText: _obscure1,
            decoration: _dec(
              'Senha',
              suffix: IconButton(
                onPressed: () => setState(() => _obscure1 = !_obscure1),
                icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: _validaSenha,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: _loading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await _submitLogin();
                      }
                    },
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Entrar'),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _loading ? null : () => setState(() => _mode = AuthMode.esqueceu),
            child: Text(
              'Esqueceu sua senha?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : () => setState(() => _mode = AuthMode.escolha),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _formRegistro() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email'),
            validator: _validaUsuarioOuEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _senhaCtrl,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: _obscure1,
            decoration: _dec(
              'Senha',
              suffix: IconButton(
                onPressed: () => setState(() => _obscure1 = !_obscure1),
                icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: _validaSenha,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmaCtrl,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: _obscure2,
            decoration: _dec(
              'Confirme a senha',
              suffix: IconButton(
                onPressed: () => setState(() => _obscure2 = !_obscure2),
                icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (v) {
              final base = _validaSenha(v);
              if (base != null) return base;
              if (v != _senhaCtrl.text) return 'As senhas não coincidem';
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: _loading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: chamar endpoint de registro
                        _showSnack('Registro: implemente o endpoint.', isError: true);
                      }
                    },
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Registrar'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : () => setState(() => _mode = AuthMode.escolha),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _formEsqueceu() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email'),
            validator: _validaUsuarioOuEmail,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: _loading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: chamar endpoint de recuperação
                        _showSnack('Recuperação de senha: implemente o endpoint.', isError: true);
                        setState(() => _mode = AuthMode.login);
                      }
                    },
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Recuperar senha'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : () => setState(() => _mode = AuthMode.login),
            child: const Text('Voltar ao login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final maxCardWidth = isLandscape ? 520.0 : 420.0;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardWidth),
                  child: Column(
                    children: [
                      _buildLogo(constraints.maxWidth * (isLandscape ? 0.35 : 0.5)),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: switch (_mode) {
                              AuthMode.escolha => _botoesEscolha(context),
                              AuthMode.login => _formLogin(),
                              AuthMode.registro => _formRegistro(),
                              AuthMode.esqueceu => _formEsqueceu(),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
