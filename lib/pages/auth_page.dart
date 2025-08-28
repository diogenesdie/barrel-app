import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacementNamed('/home');
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

  String? _validaEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
    if (!ok) return 'E-mail inválido';
    return null;
  }

  String? _validaSenha(String? v) {
    if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Widget _botoesEscolha(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            onPressed: () => setState(() => _mode = AuthMode.login),
            child: const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => _mode = AuthMode.registro),
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
                  color: Colors.white, // será mascarado pelo ShaderMask
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
            onPressed: _goHome,
            child: const Text('Continuar sem cadastro'),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _mode = AuthMode.esqueceu),
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
            decoration: _dec('Email'),
            validator: _validaEmail,
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: sua lógica de login
                  _goHome();
                }
              },
              child: const Text('Entrar'),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _mode = AuthMode.esqueceu),
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
            onPressed: () => setState(() => _mode = AuthMode.escolha),
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
            validator: _validaEmail,
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: sua lógica de registro
                  _goHome();
                }
              },
              child: const Text('Registrar'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _mode = AuthMode.escolha),
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
            validator: _validaEmail,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: enviar e-mail de recuperação
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Se existir, enviaremos instruções para o seu e-mail.')),
                  );
                  setState(() => _mode = AuthMode.login);
                }
              },
              child: const Text('Recuperar senha'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _mode = AuthMode.login),
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
