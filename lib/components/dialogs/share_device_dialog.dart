import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_home/pages/auth_page.dart';

class ShareDeviceDialog extends StatefulWidget {
  const ShareDeviceDialog({super.key});

  @override
  State<ShareDeviceDialog> createState() => _ShareDeviceDialogState();
}

class _ShareDeviceDialogState extends State<ShareDeviceDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selectedUser;
  Timer? _debounce;
  bool _isLoading = false;

  // Simulação de busca de usuários (substitua pela sua API real)
  Future<List<Map<String, dynamic>>> _mockSearchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final mockData = [
      {'id': 1, 'name': 'João Pereira', 'email': 'joao@email.com'},
      {'id': 2, 'name': 'Maria Santos', 'email': 'maria@email.com'},
      {'id': 3, 'name': 'Carlos Silva', 'email': 'carlos@email.com'},
      {'id': 4, 'name': 'Ana Costa', 'email': 'ana@email.com'},
    ];
    return mockData
        .where((u) => (u['name'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
        setState(() => _results.clear());
        return;
      }

      setState(() => _isLoading = true);

      final res = await _mockSearchUsers(query);

      if (mounted) {
        setState(() {
          _results
            ..clear()
            ..addAll(res);
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título com gradiente
            ShaderMask(
              shaderCallback: (bounds) => grad.createShader(bounds),
              child: const Text(
                "Compartilhar Dispositivo",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Usuário selecionado
            if (_selectedUser != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColorLight.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColorLight,
                      child: Text(
                        _selectedUser!['name'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedUser!['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedUser!['email'],
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _selectedUser = null);
                      },
                    ),
                  ],
                ),
              ),

            if (_selectedUser != null) const SizedBox(height: 16),

            if (_selectedUser == null) ...[
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar usuário pelo nome...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Estado de carregamento
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),

            // Resultados da busca (só aparece se não houver usuário selecionado)
            if (_selectedUser == null && !_isLoading && _results.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColorLight,
                          child: Text(
                            user['name'][0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['name']),
                        subtitle: Text(user['email'],
                            style: const TextStyle(fontSize: 13)),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).primaryColorLight,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedUser = user;
                            _searchCtrl.clear();
                            _results.clear();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

            if (_selectedUser == null && 
                _results.isEmpty && 
                !_isLoading && 
                _searchCtrl.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Nenhum usuário encontrado',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            // Botão confirmar (só habilitado se houver usuário selecionado)
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: _selectedUser != null
                    ? () {
                        // Aqui você pode implementar a lógica de compartilhamento real
                        Navigator.pop(context, _selectedUser);
                      }
                    : null,
                child: Text(
                  _selectedUser != null 
                      ? "Compartilhar" 
                      : "Selecione um usuário",
                ),
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      ),
    );
  }
}