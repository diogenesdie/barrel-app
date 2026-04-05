// =============================================================================
// manage_shares_page.dart
//
// Tela de gerenciamento dos compartilhamentos enviados pelo usuário.
// Lista os compartilhamentos ativos (não revogados) criados pelo usuário logado
// e permite revogá-los individualmente.
// Acessível via ícone na AppBar da DevicesPage.
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Projeto — core e modelos
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device_share.dart';
import 'package:smart_home/models/device_share_repository.dart';

// Projeto — páginas e utils
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/session_utils.dart';

/// Tela de listagem e revogação dos compartilhamentos criados pelo usuário.
class ManageShares extends StatefulWidget {
  const ManageShares({super.key});

  @override
  State<ManageShares> createState() => _ManageSharesState();
}

class _ManageSharesState extends State<ManageShares> {
  late DeviceShareRepository _shareRepo;

  bool _isLoading = false;
  List<DeviceShare> _myShares = [];

  @override
  void initState() {
    super.initState();
    _shareRepo = DeviceShareRepository(apiBaseUrl: BASE_API_URL);
    _loadMyShares();
  }

  // SECTION: Carregamento de dados

  /// Busca os compartilhamentos do usuário logado e filtra os não revogados.
  Future<void> _loadMyShares() async {
    setState(() => _isLoading = true);

    try {
      final user = await SessionUtils.getUser();
      if (user == null) {
        setState(() {
          _myShares = [];
        });
        return;
      }

      final shares = await _shareRepo.getShares();

      setState(() {
        _myShares = shares.where((share) => share.ownerId == user['user_id'] && share.status != 'R').toList();
      });
    } catch (e) {
      debugPrint("Erro ao carregar meus compartilhamentos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao carregar compartilhamentos"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // SECTION: Ações sobre compartilhamentos

  /// Exibe confirmação e revoga o [share] selecionado via API.
  Future<void> _revokeShare(DeviceShare share) async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.link_off_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Revogar acesso?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Você está prestes a remover o acesso de "${share.sharedWithName}". '
                'Essa pessoa perderá o controle do ${share.type?.toLowerCase()}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Revogar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      try {
        await _shareRepo.revokeShare(share.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compartilhamento revogado com sucesso"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadMyShares();
      } catch (e) {
        debugPrint("Erro ao revogar compartilhamento: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erro ao revogar compartilhamento"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _statusChip(DeviceShare share) {
    Color bg;
    Color fg;
    String label;

    switch (share.status) {
      case 'P':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade800;
        label = 'Pendente';
        break;
      case 'A':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        label = 'Ativo';
        break;
      case 'R':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        label = 'Revogado/Recusado';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = share.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _shareCard(DeviceShare share) {
    final isRevoked = share.status == 'R';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFB8860B),
                        const Color(0xFF5D4037),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB8860B).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      share.sharedWithName?.isNotEmpty == true
                          ? share.sharedWithName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              share.sharedWithName ?? 'Usuário desconhecido',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade900,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _statusChip(share),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Compartilhou um ${share.shareTypeText.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (share.sharedItemName != null && share.sharedItemName!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                share.type == 'device' ? Icons.devices_rounded : FontAwesomeIcons.layerGroup,
                                size: 15,
                                color: const Color(0xFFB8860B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  share.sharedItemName!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: ElevatedButton(
              onPressed: isRevoked ? null : () => _revokeShare(share),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRevoked ? Colors.grey.shade300 : Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: isRevoked ? 0 : 4,
                shadowColor: Colors.red.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.link_off_rounded,
                    size: 20,
                    color: isRevoked ? Colors.grey.shade500 : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRevoked ? 'Acesso revogado' : 'Revogar acesso',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isRevoked ? Colors.grey.shade500 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final maxWidth = isLandscape ? 720.0 : 520.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus compartilhamentos'),
        elevation: 10,
        shadowColor: Colors.grey[200],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFB8860B),
                Color(0xFF5D4037),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMyShares,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(),
                    )
                  : _myShares.isEmpty
                      ? _EmptyState(onRefresh: _loadMyShares)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          itemCount: _myShares.length,
                          itemBuilder: (context, index) {
                            final share = _myShares[index];
                            return _shareCard(share);
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFB8860B).withOpacity(0.1),
                        const Color(0xFF5D4037).withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    FontAwesomeIcons.shareNodes,
                    color: const Color(0xFFB8860B),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Nenhum compartilhamento ativo",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Quando você compartilhar um dispositivo ou grupo, ele aparecerá aqui.\nVocê pode revogar o acesso a qualquer momento.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: () => onRefresh(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "Atualizar lista",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}