import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device_share.dart';
import 'package:smart_home/models/device_share_repository.dart';
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/session_utils.dart';

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

  Future<void> _revokeShare(DeviceShare share) async {
  final confirmar = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de alerta
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFB8860B), Color(0xFF5D4037)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),

            // Título
            const Text(
              'Revogar acesso?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3E2723),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Texto de confirmação
            Text(
              'Você está prestes a remover o acesso de "${share.sharedWithName}". '
              'Essa pessoa perderá o controle do ${share.type?.toLowerCase()}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 22),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.brown.shade400.withOpacity(0.5),
                        width: 1.3,
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: Colors.redAccent.withOpacity(0.3),
                      elevation: 4,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Revogar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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


  // Badge de status (pendente / ativo / etc)
  Widget _statusChip(DeviceShare share) {
    // Ajusta as cores de acordo com o status
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _shareCard(DeviceShare share) {
    final isRevoked = share.status == 'R';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB8860B).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar circular
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFB8860B).withOpacity(0.25),
                    const Color(0xFF5D4037).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  share.sharedWithName?.isNotEmpty == true ? share.sharedWithName![0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Conteúdo principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome + status chip
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          share.sharedWithName ?? 'Usuário desconhecido',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.brown.shade800,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _statusChip(share),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Texto de descrição
                  Text(
                    'Você compartilhou um ${share.shareTypeText.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.brown.shade600,
                      height: 1.4,
                    ),
                  ),

                  if (share.sharedItemName != null && share.sharedItemName!.trim().isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              share.type == 'device' ? Icons.devices : FontAwesomeIcons.layerGroup,
                              size: 14,
                              color: Colors.brown.shade400,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                share.sharedItemName!,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )),

                  const SizedBox(height: 12),

                  // Ações
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _RevokeButton(
                        enabled: !isRevoked,
                        onTap: () => _revokeShare(share),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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

class _RevokeButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _RevokeButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = enabled ? Colors.redAccent : Colors.grey;

    return Tooltip(
      message: enabled ? 'Revogar acesso' : 'Acesso já revogado',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: baseColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 16,
                color: baseColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Revogar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: baseColor,
                ),
              ),
            ],
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
                  child: Icon(
                    FontAwesomeIcons.shareNodes,
                    color: Colors.black54,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Nenhum compartilhamento ativo",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Quando você compartilhar um dispositivo ou grupo, ele aparecerá aqui.\nVocê pode revogar o acesso a qualquer momento.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                GradientButton(
                  onPressed: () => onRefresh(),
                  child: const Text(
                    "Atualizar lista",
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
}
