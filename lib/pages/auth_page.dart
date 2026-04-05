// =============================================================================
// auth_page.dart
//
// Tela de autenticação do aplicativo Barrel Smart Home.
//
// Modos de exibição controlados por [AuthMode]:
//   - escolha:  botões para entrar, registrar ou continuar sem cadastro
//   - login:    formulário de login (usuário/e-mail + senha)
//   - registro: formulário completo de cadastro
//   - esqueceu: recuperação de senha por e-mail
//
// Componentes locais:
//   - [GradientButton]: botão com gradiente reutilizável (usado em outras telas)
//   - [appGradient]:    função auxiliar de gradiente do tema (usada em outras telas)
//
// Nota: [GradientButton] e [appGradient] são importados por
// checking_session_page.dart, devices_page.dart e create_group_dialog.dart.
// Candidatos à extração futura para lib/core/theme_utils.dart.
// =============================================================================

// Dart SDK
import 'dart:async';
import 'dart:convert';

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:http/http.dart' as http;

// Projeto — core e modelos
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group_repository.dart';

// Projeto — utils
import 'package:smart_home/utils/session_utils.dart';

/// Modos de exibição da tela de autenticação.
enum AuthMode { escolha, login, registro, esqueceu }

// Nota: função duplicada em devices_page.dart, checking_session_page.dart e create_group_dialog.dart.
// Candidata à extração futura para lib/core/theme_utils.dart.
LinearGradient appGradient(BuildContext context) => LinearGradient(
      colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

/// Botão com gradiente do tema aplicado, suportando estado desabilitado e de erro.
///
/// - [error]: aplica gradiente vermelho para indicar falha.
/// - [disabled]: aplica opacidade 50% e desabilita o toque.
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;
  final bool error;
  final bool disabled;

  const GradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
    this.borderRadius = 12,
    this.elevation = 0,
    this.error = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final grad = error
        ? LinearGradient(
            colors: [
              Colors.red.shade400,
              Colors.red.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : appGradient(context);

    final isDisabled = onPressed == null || disabled;

    final gradDisabled = error
        ? LinearGradient(
            colors: [
              Colors.red.shade200.withOpacity(0.5),
              Colors.red.shade400.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Theme.of(context).primaryColorLight.withOpacity(0.5),
              Theme.of(context).primaryColor.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Ink(
        decoration: BoxDecoration(
          gradient: isDisabled ? gradDisabled : grad,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: TextStyle(
                color: error ? Colors.white : Colors.white,
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

const String _loginUrl = "$BASE_API_AUTH_URL/login";
const String _registerUrl = "$BASE_API_AUTH_URL/register";

/// Tela de autenticação com suporte a login, registro e recuperação de senha.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  // SECTION: Estado do modo e formulário
  AuthMode _mode = AuthMode.escolha;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _senhaFocus = FocusNode();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  bool _showLogo = false;
  bool _showBarrel = false;
  bool _showSmartHome = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();

    _checkExistingSession();

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _showLogo = true);
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _showBarrel = true);
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      setState(() => _showSmartHome = true);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() => _showForm = true);
    });

    _senhaFocus.addListener(() {
      if (_senhaFocus.hasFocus) {
        _senhaCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _senhaCtrl.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    _focusUser.dispose();
    _focusEmail.dispose();
    _focusSenha.dispose();
    _focusConfirma.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  // SECTION: Verificação de sessão existente

  /// Verifica se já há sessão válida e redireciona para /home se positivo.
  Future<void> _checkExistingSession() async {
    final token = await SessionUtils.getToken();
    final expiresAtDateTime = await SessionUtils.getExpiresAt();

    if (token != null && expiresAtDateTime != null && DateTime.now().isBefore(expiresAtDateTime)) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = expiresAtDateTime.millisecondsSinceEpoch;

      if (token.isNotEmpty && now < expiresAt) {
        if (!mounted) return;
        await _goHome();
      } else {
        await SessionUtils.clearSession();
      }
    }
  }

  // SECTION: Sincronização de dados após login/registro

  /// Sincroniza grupos e dispositivos da API para o cache local após autenticação.
  Future<void> syncData() async {
    final groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);
    final deviceRepo = DeviceRepository(apiBaseUrl: BASE_API_URL);

    await groupRepo.syncGroupsGet();
    await deviceRepo.syncDevicesGet();
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // SECTION: Submissão de formulários

  /// Valida e envia o formulário de login. Salva sessão e sincroniza dados em caso de sucesso.
  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _emailCtrl.text.trim();
    final password = _senhaCtrl.text;
    
    await SessionUtils.clearSession();

    setState(() => _loading = true);
    try {
      final resp = await http
          .post(
            Uri.parse(_loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = body['data']['token'] as String?;

        if (token == null || token.isEmpty) {
          _showSnack('Resposta sem token. Tente novamente.', isError: true);
        } else {
          await SessionUtils.saveSession(body['data'], password);

          _showSnack('Login realizado com sucesso!');

          await syncData();
          await _goHome();
        }
      } else {
        String msg = 'Falha no login (${resp.statusCode}).';
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['message'] is String) {
            msg = data['message'];
            switch (msg) {
              case 'session not found':
                msg = 'Sessão não encontrada.';
                break;
              case 'session expired':
                msg = 'Sessão expirada.';
                break;
              case 'session manually inactivated':
                msg = 'Sessão manualmente inativada.';
                break;
              case 'invalid password':
                msg = 'Senha inválida.';
                break;
              case 'unauthorized':
                msg = 'Não autorizado.';
                break;
              case 'failed to generate token':
                msg = 'Falha ao gerar token.';
                break;
              case 'failed to update token':
                msg = 'Falha ao atualizar token.';
                break;
              default:
                msg = 'Erro desconhecido. Tente novamente.';
            }
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

  /// Valida e envia o formulário de registro. Salva sessão e sincroniza dados em caso de sucesso.
  Future<void> _submitRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeCtrl.text.trim();
    final username = _userCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;

    setState(() => _loading = true);

    try {
      // 1. cria usuário (isso deve disparar o Register no backend e já criar sessão)
      final resp = await http
          .post(
            Uri.parse(_registerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'type': 'U', // ou o tipo padrão que teu backend espera
              'username': username,
              'name': nome,
              'email': email,
              'password': senha,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // a tua Register() do backend agora retorna *Session (mesmo formato do Login)
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;

        final token = data?['token'] as String?;
        if (token == null || token.isEmpty) {
          _showSnack('Registro OK mas resposta sem token.', isError: true);
        } else {
          // salva sessão local igual no login
          await SessionUtils.saveSession(data!, senha);

          _showSnack('Conta criada com sucesso!');

          await syncData();
          await _goHome();
        }
      } else {
        String msg = 'Falha no registro (${resp.statusCode}).';
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['message'] is String) {
            msg = data['message'];
            if (msg == 'user already exists') {
              msg = 'Usuário já existe.';
            }
          }
        } catch (_) {}
        _showSnack(msg, isError: true);
      }
    } on TimeoutException {
      _showSnack('Tempo esgotado. Verifique sua conexão.', isError: true);
    } catch (e) {
      _showSnack('Erro inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // SECTION: Helpers de UI

  /// Exibe um SnackBar com [text]. Vermelho se [isError], verde caso contrário.
  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // SECTION: Widgets de animação

  /// Anima um widget com fade-in + slide de baixo para cima. Persiste visível após aparecer.
  Widget _fadeInUpPersistent({
    required bool visible,
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeOut,
        offset: visible ? Offset.zero : const Offset(0, 0.2), // 20px "baixo"
        child: child,
      ),
    );
  }

  Widget _fadeInDownRoll({
    required bool visible,
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, -1.0),
        child: AnimatedRotation(
          duration: duration,
          curve: Curves.easeOutCubic,
          turns: visible ? 0 : -.5,
          child: child,
        ),
      ),
    );
  }

  Widget _fadeInDown({
    required bool visible,
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeOut,
        // negativo => começa acima, positivo => começa abaixo
        offset: visible ? Offset.zero : const Offset(0, -0.2),
        child: child,
      ),
    );
  }

  /// Constrói o logo animado com rotação do ícone e fade-in sequencial dos textos.
  Widget _buildAnimatedLogo(double size) {
    return Column(
      children: [
        _fadeInDownRoll(
          visible: _showLogo,
          child: Image.asset('assets/logo.png', width: size),
        ),
        const SizedBox(height: 16),
        _fadeInDown(
          visible: _showBarrel,
          child: ShaderMask(
            shaderCallback: (bounds) => appGradient(context).createShader(bounds),
            child: const Text(
              'BARREL',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
                color: Colors.white,
              ),
            ),
          ),
        ),
        _fadeInDown(
          visible: _showSmartHome,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SMART',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: appGradient(context),
                ),
              ),
              const Text(
                'HOME',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // NOTA: Versão alternativa do logo sem animação — mantida para referência histórica.
  //       Para restaurar, remover comentários e chamar _buildLogoNoAnimation em vez de _buildAnimatedLogo.
  // Widget _buildLogoNoAnimation(double maxWidth) {
  //   final size = maxWidth.clamp(120, 180).toDouble();

  //   return Padding(
  //     padding: const EdgeInsets.only(top: 16, bottom: 24),
  //     child: Column(
  //       children: [
  //         Image.asset('assets/logo.png', width: size),
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: [
  //             ShaderMask(
  //               shaderCallback: (bounds) => appGradient(context).createShader(bounds),
  //               child: const Text(
  //                 'BARREL',
  //                 style: TextStyle(
  //                   fontSize: 32,
  //                   fontWeight: FontWeight.w800,
  //                   letterSpacing: 1.5,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 const Text(
  //                   'Smart',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: Colors.grey),
  //                 ),
  //                 Container(
  //                   margin: const EdgeInsets.symmetric(horizontal: 4),
  //                   width: 4,
  //                   height: 4,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     gradient: appGradient(context),
  //                   ),
  //                 ),
  //                 const Text(
  //                   'Home',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: Colors.grey),
  //                 )
  //               ],
  //             )
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // SECTION: Helpers de formulário e validação

  /// Retorna a decoração padrão dos campos de formulário da tela de auth.
  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: TextStyle(color: Colors.grey[700]),
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

  // SECTION: Widgets de formulário por modo

  /// Exibe os três botões do modo [AuthMode.escolha]: Entrar, Registrar, Continuar sem cadastro.
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
            onPressed: _loading ? null : () {
              // Criar grupo padrao
              GroupRepository groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);
              groupRepo.createDefaultGroup();
              _goHome();
            },
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

  /// Formulário do modo [AuthMode.login].
  Widget _formLogin() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email ou usuário', Icons.person),
            validator: _validaUsuarioOuEmail,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_senhaFocus);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _senhaCtrl,
            autofillHints: const [AutofillHints.password],
            obscureText: _obscure1,
            focusNode: _senhaFocus,
            decoration: _dec(
              'Senha',
              Icons.lock,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure1 = !_obscure1),
                icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: _validaSenha,
            onFieldSubmitted: (_) async {
              if (_formKey.currentState!.validate() && !_loading) {
                await _submitLogin();
              }
            },
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
              child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Entrar'),
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

  String? _validaNome(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe seu nome';
    if (v.trim().length < 2) return 'Nome muito curto';
    return null;
  }

  String? _validaUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe um usuário';
    if (!RegExp(r'^[a-zA-Z0-9._-]{3,}$').hasMatch(v.trim())) {
      return 'Use pelo menos 3 caracteres (letras/números/ponto/_/-)';
    }
    return null;
  }

  String? _validaEmail(String? v) {
    if (v == null || v.isEmpty) return 'Informe seu e-mail';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
    if (!ok) return 'E-mail inválido';
    return null;
  }

  // Adicione no início da classe _AuthPageState:
  final _focusUser = FocusNode();
  final _focusEmail = FocusNode();
  final _focusSenha = FocusNode();
  final _focusConfirma = FocusNode();

  Widget _formRegistro() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // NOME
          TextFormField(
            controller: _nomeCtrl,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Nome completo', Icons.person_outline),
            validator: _validaNome,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusUser),
          ),
          const SizedBox(height: 12),

          // USERNAME
          TextFormField(
            controller: _userCtrl,
            focusNode: _focusUser,
            autofillHints: const [AutofillHints.username],
            decoration: _dec('Usuário', Icons.person),
            validator: _validaUsername,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusEmail),
          ),
          const SizedBox(height: 12),

          // EMAIL
          TextFormField(
            controller: _emailCtrl,
            focusNode: _focusEmail,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email', Icons.email),
            validator: _validaEmail,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusSenha),
          ),
          const SizedBox(height: 12),

          // SENHA
          TextFormField(
            controller: _senhaCtrl,
            focusNode: _focusSenha,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: _obscure1,
            decoration: _dec(
              'Senha',
              Icons.lock,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure1 = !_obscure1),
                icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: _validaSenha,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusConfirma),
          ),
          const SizedBox(height: 12),

          // CONFIRMAR SENHA
          TextFormField(
            controller: _confirmaCtrl,
            focusNode: _focusConfirma,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: _obscure2,
            decoration: _dec(
              'Confirme a senha',
              Icons.lock,
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
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) async {
              if (_formKey.currentState!.validate() && !_loading) {
                await _submitRegistro(); // dispara o botão
              }
            },
          ),
          const SizedBox(height: 16),

          // BOTÃO REGISTRAR
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: _loading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await _submitRegistro();
                      }
                    },
              child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Registrar'),
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
            decoration: _dec('Email', Icons.email),
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
              child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Recuperar senha'),
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
                  _buildAnimatedLogo(maxCardWidth * (isLandscape ? 0.35 : 0.5)),
                  const SizedBox(height: 24),
                  _fadeInUpPersistent(
                    visible: _showForm,
                    child: Card(
                      color: Colors.white.withOpacity(0.7),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
