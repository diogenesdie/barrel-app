import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String? _shareCode;

  bool _bioLogin = false;
  bool _bioEditDevice = false;
  bool _bioRemoveDevice = false;

  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = SessionUtils.getUser();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final user = await SessionUtils.getUser();
    final nome = user?['name'] as String?;
    final email = user?['email'] as String?;
    final telefone = user?['telefone'] as String?;

    final backendCode = (user?['code'])?.toString();
    final derived = "NÃO DISPONÍVEL";

    final bioLogin = (user?['biometric_login'] as bool?) ?? false;
    final bioEditDevice = (user?['biometric_edit'] as bool?) ?? false;
    final bioRemoveDevice = (user?['biometric_remove'] as bool?) ?? false;

    setState(() {
      _nomeCtrl.text = nome ?? '';
      _emailCtrl.text = email ?? '';
      _telefoneCtrl.text = telefone ?? '';
      _shareCode = (backendCode?.isNotEmpty == true ? backendCode : derived)?.toUpperCase();

      _bioLogin = bioLogin;
      _bioEditDevice = bioEditDevice;
      _bioRemoveDevice = bioRemoveDevice;
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

    final data = {
      "name": _nomeCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "telefone": _telefoneCtrl.text.trim(),
      "biometric_login": _bioLogin,
      "biometric_edit": _bioEditDevice,
      "biometric_remove": _bioRemoveDevice,
    };

    final ok = await SessionUtils.updateUserProfile(data);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfil atualizado com sucesso."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao atualizar perfil. Tente novamente."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  Future<void> _copyShareCode() async {
    if (_shareCode == null || _shareCode!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _shareCode!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _senhaNovaCtrl.dispose();
    _senhaConfirmaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture, // <= agora é estável, não recria a cada rebuild
      builder: (context, snapshot) {
        // ainda está carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // sem login
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          FontAwesomeIcons.userLarge,
                          color: Colors.black54,
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Você não está logado",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Faça login para acessar seu perfil e recursos personalizados.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),
                      GradientButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        ),
                        child: const Text(
                          "Entrar na conta",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // logado
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // HEADER / AVATAR / CÓDIGO COMPARTILHAMENTO
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _nomeCtrl.text.isEmpty ? "Usuário Smart" : _nomeCtrl.text,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _emailCtrl.text,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _copyShareCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_2, color: Colors.grey[700]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Código de compartilhamento',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _shareCode ?? '------',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar',
                                onPressed: _copyShareCode,
                                icon: const Icon(Icons.copy_rounded),
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // CARD PRINCIPAL
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

                          const SizedBox(height: 24),

                          // BLOCO SEGURANÇA / BIOMETRIA
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Segurança e acesso",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Use biometria (digital/rosto) para proteger ações sensíveis.",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    "Entrar no app",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Exigir biometria no login",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  value: _bioLogin,
                                  onChanged: (val) {
                                    setState(() {
                                      _bioLogin = val;
                                      // TODO: persistir preferência login biométrico
                                    });
                                  },
                                ),
                                const Divider(height: 16),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    "Editar dispositivo",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Pedir biometria antes de abrir a tela de edição",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  value: _bioEditDevice,
                                  onChanged: (val) {
                                    setState(() {
                                      _bioEditDevice = val;
                                      // TODO: persistir preferência de edição protegida
                                    });
                                  },
                                ),
                                const Divider(height: 16),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    "Remover dispositivo",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Antes de desconectar/remover um device, exigir biometria",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  value: _bioRemoveDevice,
                                  onChanged: (val) {
                                    setState(() {
                                      _bioRemoveDevice = val;
                                      // TODO: persistir preferência de remoção protegida
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ALTERAR SENHA
                          ExpansionTile(
                            collapsedIconColor: Colors.grey,
                            iconColor: Colors.grey[700],
                            title: const Text(
                              'Alterar senha',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
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
                                    onPressed: () => setState(() {
                                      _obscureAtual = !_obscureAtual;
                                    }),
                                    icon: Icon(
                                      _obscureAtual ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey[600],
                                    ),
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
                                    onPressed: () => setState(() {
                                      _obscureNova = !_obscureNova;
                                    }),
                                    icon: Icon(
                                      _obscureNova ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey[600],
                                    ),
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
                                    onPressed: () => setState(() {
                                      _obscureConfirma = !_obscureConfirma;
                                    }),
                                    icon: Icon(
                                      _obscureConfirma ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              GradientButton(
                                onPressed: _alterarSenha,
                                child: const Text("Atualizar senha"),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),

                          const SizedBox(height: 20),

                          GradientButton(
                            onPressed: _salvarPerfil,
                            child: const Text("Salvar alterações"),
                          ),

                          const SizedBox(height: 12),

                          TextButton(
                            onPressed: () async {
                              await SessionUtils.clearSession();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/auth',
                                (r) => false,
                              );
                            },
                            child: const Text(
                              "Sair da conta",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          const SizedBox(height: 20),

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Theme.of(context).primaryColorLight),
                            ),
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove("tutorial_comm_mode_shown");
                              await prefs.remove("tutorial_add_device_shown");
                              await prefs.remove("tutorial_reorder_shown");
                              await prefs.remove("tutorial_device_drag_shown");

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Tutoriais reiniciados! Eles aparecerão novamente."),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text(
                              "Rever tutoriais",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
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
