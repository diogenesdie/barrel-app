import 'package:flutter/material.dart';
import 'package:smart_home/pages/auth_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomeCtrl = TextEditingController(text: 'Érica');
  final _emailCtrl = TextEditingController(text: 'erica@exemplo.com');
  final _telefoneCtrl = TextEditingController(text: '+55 (51) 99999-9999');

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
    if (_senhaAtualCtrl.text.isEmpty ||
        _validaSenha(_senhaNovaCtrl.text) != null ||
        _senhaNovaCtrl.text != _senhaConfirmaCtrl.text) {
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

  void _trocarFoto() {
    // TODO: abrir bottom sheet (galeria/câmera)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trocar foto (não implementado)')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      // Avatar + botão
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
                                  child: const CircleAvatar(
                                    radius: 44,
                                    backgroundImage: AssetImage('assets/avatar_placeholder.png'), // troque pelo seu asset
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _trocarFoto,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: appGradient(context),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Editar foto',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card com formulário (mesmo look da Auth)
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Dados pessoais
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
                                // Endereço (opcional)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Endereço (opcional)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _enderecoCtrl,
                                  decoration: _dec('Logradouro, número'),
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _cidadeCtrl,
                                        decoration: _dec('Cidade'),
                                        textCapitalization: TextCapitalization.words,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 110,
                                      child: TextFormField(
                                        controller: _estadoCtrl,
                                        decoration: _dec('UF'),
                                        textCapitalization: TextCapitalization.characters,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _cepCtrl,
                                  decoration: _dec('CEP'),
                                  keyboardType: TextInputType.number,
                                ),

                                const SizedBox(height: 20),
                                // Preferências
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
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Notificações por push'),
                                  value: _notifPush,
                                  onChanged: (v) => setState(() => _notifPush = v),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Notificações por e-mail'),
                                  value: _notifEmail,
                                  onChanged: (v) => setState(() => _notifEmail = v),
                                ),

                                const SizedBox(height: 20),
                                // Alterar senha (collapse)
                                ExpansionTile(
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
                                        width: 220,
                                        child: GradientButton(
                                          onPressed: _alterarSenha,
                                          child: const Text('Atualizar senha'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                // Ações principais
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
                                    onPressed: () {
                                      // TODO: sair (limpar sessão, prefs, etc.)
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
}
