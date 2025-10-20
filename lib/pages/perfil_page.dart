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

  final _senhaAtualCtrl = TextEditingController();
  final _senhaNovaCtrl = TextEditingController();
  final _senhaConfirmaCtrl = TextEditingController();

  bool _obscureAtual = true;
  bool _obscureNova = true;
  bool _obscureConfirma = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado!')),
    );
  }

  Future<void> _alterarSenha() async {
    if (_senhaAtualCtrl.text.isEmpty || _senhaNovaCtrl.text.isEmpty || _senhaNovaCtrl.text != _senhaConfirmaCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifique os campos de senha.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha alterada com sucesso.')),
    );
    _senhaAtualCtrl.clear();
    _senhaNovaCtrl.clear();
    _senhaConfirmaCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SessionUtils.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline, color: Colors.grey, size: 80),
                    const SizedBox(height: 16),
                    const Text(
                      "Você não está logado",
                      style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Entre na sua conta para acessar o perfil.",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Fazer login", style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Avatar + header
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey, size: 48),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _nomeCtrl.text.isEmpty ? "Usuário Smart" : _nomeCtrl.text,
                        style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _emailCtrl.text,
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Form card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            "Informações pessoais",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nomeCtrl,
                            decoration: _dec('Nome completo', Icons.person_outline),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _dec('E-mail', Icons.email_outlined),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _telefoneCtrl,
                            decoration: _dec('Telefone', Icons.phone_outlined),
                          ),
                          const SizedBox(height: 20),
                          ExpansionTile(
                            collapsedIconColor: Colors.grey,
                            iconColor: Colors.grey[700],
                            title: const Text(
                              'Alterar senha',
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                            children: [
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _senhaAtualCtrl,
                                obscureText: _obscureAtual,
                                decoration: _dec(
                                  'Senha atual',
                                  Icons.lock_outline,
                                  suffix: IconButton(
                                    onPressed: () => setState(() => _obscureAtual = !_obscureAtual),
                                    icon: Icon(_obscureAtual ? Icons.visibility : Icons.visibility_off, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _senhaNovaCtrl,
                                obscureText: _obscureNova,
                                decoration: _dec(
                                  'Nova senha',
                                  Icons.key_outlined,
                                  suffix: IconButton(
                                    onPressed: () => setState(() => _obscureNova = !_obscureNova),
                                    icon: Icon(_obscureNova ? Icons.visibility : Icons.visibility_off, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _senhaConfirmaCtrl,
                                obscureText: _obscureConfirma,
                                decoration: _dec(
                                  'Confirmar nova senha',
                                  Icons.lock_reset_outlined,
                                  suffix: IconButton(
                                    onPressed: () => setState(() => _obscureConfirma = !_obscureConfirma),
                                    icon: Icon(_obscureConfirma ? Icons.visibility : Icons.visibility_off, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              GradientButton(onPressed: _alterarSenha, child: const Text("Atualizar senha")),
                              const SizedBox(height: 10),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GradientButton(onPressed: _salvarPerfil, child: const Text("Salvar alterações")),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              await SessionUtils.clearSession();
                              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (r) => false);
                            },
                            child: const Text(
                              "Sair da conta",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
