import 'package:flutter/material.dart';
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/session_utils.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  final _enderecoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();

  final _senhaAtualCtrl = TextEditingController();
  final _senhaNovaCtrl = TextEditingController();
  final _senhaConfirmaCtrl = TextEditingController();

  bool _notifPush = true;
  bool _notifEmail = true;
  bool _obscureAtual = true;
  bool _obscureNova = true;
  bool _obscureConfirma = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _enderecoCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _cepCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _senhaNovaCtrl.dispose();
    _senhaConfirmaCtrl.dispose();
    super.dispose();
  }

  void _loadUserInfo() async {
    final user = await SessionUtils.getUser();
    final nome = user?['name'] as String?;
    final email = user?['email'] as String?;
    final telefone = user?['telefone'] as String?;

    setState(() {
      _nomeCtrl.text = nome ?? '';
      _emailCtrl.text = email ?? '';
      _telefoneCtrl.text = telefone ?? '';
    });
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

  String? _validaObrigatorio(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? _validaSenha(String? v) {
    if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    // TODO: salvar no backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado!')),
    );
  }

  Future<void> _alterarSenha() async {
    if (_senhaAtualCtrl.text.isEmpty || _validaSenha(_senhaNovaCtrl.text) != null || _senhaNovaCtrl.text != _senhaConfirmaCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifique os campos de senha.')),
      );
      return;
    }
    // TODO: chamar endpoint de alteração de senha
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha alterada com sucesso.')),
    );
    _senhaAtualCtrl.clear();
    _senhaNovaCtrl.clear();
    _senhaConfirmaCtrl.clear();
  }

  Widget _buildPerfil(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final maxCardWidth = isLandscape ? 720.0 : 520.0;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardWidth),
                  child: Column(
                    children: [
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Dados pessoais',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nomeCtrl,
                                  decoration: _dec('Nome completo'),
                                  validator: _validaObrigatorio,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailCtrl,
                                  decoration: _dec('Email'),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validaEmail,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _telefoneCtrl,
                                  decoration: _dec('Telefone'),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Preferências',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.brown[50],
                                    border: Border.all(
                                      color: Colors.brown[50]!,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Notificações por push'),
                                    value: _notifPush,
                                    onChanged: (v) => setState(() => _notifPush = v),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.brown[50],
                                    border: Border.all(
                                      color: Colors.brown[50]!,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Notificações por e-mail'),
                                    value: _notifEmail,
                                    onChanged: (v) => setState(() => _notifEmail = v),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.brown[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: Text(
                                      'Alterar senha',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    children: [
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _senhaAtualCtrl,
                                        obscureText: _obscureAtual,
                                        decoration: _dec(
                                          'Senha atual',
                                          suffix: IconButton(
                                            onPressed: () => setState(() => _obscureAtual = !_obscureAtual),
                                            icon: Icon(_obscureAtual ? Icons.visibility : Icons.visibility_off),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _senhaNovaCtrl,
                                        obscureText: _obscureNova,
                                        decoration: _dec(
                                          'Nova senha',
                                          suffix: IconButton(
                                            onPressed: () => setState(() => _obscureNova = !_obscureNova),
                                            icon: Icon(_obscureNova ? Icons.visibility : Icons.visibility_off),
                                          ),
                                        ),
                                        validator: _validaSenha,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _senhaConfirmaCtrl,
                                        obscureText: _obscureConfirma,
                                        decoration: _dec(
                                          'Confirmar nova senha',
                                          suffix: IconButton(
                                            onPressed: () => setState(() => _obscureConfirma = !_obscureConfirma),
                                            icon: Icon(_obscureConfirma ? Icons.visibility : Icons.visibility_off),
                                          ),
                                        ),
                                        validator: (v) {
                                          final base = _validaSenha(v);
                                          if (base != null) return base;
                                          if (v != _senhaNovaCtrl.text) return 'As senhas não coincidem';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                          child: GradientButton(
                                            onPressed: _alterarSenha,
                                            child: const Text('Atualizar senha'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GradientButton(
                                        onPressed: _salvarPerfil,
                                        child: const Text('Salvar alterações'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await SessionUtils.clearSession();
                                      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Theme.of(context).primaryColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (rect) => appGradient(context).createShader(rect),
                                      child: const Text(
                                        'Sair da conta',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return FutureBuilder<Map<String, dynamic>?>(
    future: SessionUtils.getUser(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final user = snapshot.data;
      if (user == null) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 20),
                        Text(
                          "Você ainda não está logado",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Entre na sua conta para gerenciar perfil, dispositivos e preferências.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuthPage(),
                              ),
                            );
                          },
                          child: const Text("Fazer login"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return _buildPerfil(context);
    },
  );
}
}
