// =============================================================================
// sharing_notification_widget.dart
//
// Widget expansível que lista solicitações de compartilhamento pendentes.
// Exibe um badge com a contagem e permite aceitar ou recusar cada solicitação.
//
// Classes neste arquivo:
//   - [SharingNotificationWidget]: widget público expansível
//   - [_ShareRequestItem]:         item individual de uma solicitação
//   - [_ActionButton]:             botão animado de aceitar/recusar
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Projeto — modelos
import 'package:smart_home/models/device_share.dart';

/// Widget expansível de notificação de compartilhamentos pendentes.
///
/// Ao clicar, expande para exibir cada solicitação com botões de aceitar/recusar.
/// Retorna ao estado colapsado automaticamente se [pendingShares] ficar vazio.
class SharingNotificationWidget extends StatefulWidget {
  final List<DeviceShare> pendingShares;
  final Function(int shareId) onAccept;
  final Function(int shareId) onReject;

  const SharingNotificationWidget({
    super.key,
    required this.pendingShares,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<SharingNotificationWidget> createState() => _SharingNotificationWidgetState();
}

class _SharingNotificationWidgetState extends State<SharingNotificationWidget> with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingShares.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8860B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FontAwesomeIcons.shareNodes,
                      color: Colors.brown.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitações de Compartilhamento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.pendingShares.length} solicitaç${widget.pendingShares.length == 1 ? 'ão' : 'ões'} pendente${widget.pendingShares.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.brown.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFB8860B),
                          Colors.brown.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.pendingShares.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFB8860B).withOpacity(0.25),
                  ),
                ),
              ),
              child: Column(
                children: widget.pendingShares.map((share) {
                  return _ShareRequestItem(
                    share: share,
                    onAccept: () => widget.onAccept(share.id),
                    onReject: () => widget.onReject(share.id),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item individual exibindo as informações de uma solicitação de compartilhamento.
class _ShareRequestItem extends StatelessWidget {
  final DeviceShare share;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ShareRequestItem({
    required this.share,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFB8860B).withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Column(children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFB8860B).withOpacity(0.15),
              child: Text(
                share.ownerName.isNotEmpty ? share.ownerName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.brown.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    share.ownerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade700,
                    ),
                  ),
                  Text(
                    'quer compartilhar um ${share.shareTypeText.toLowerCase()} com você',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.close,
                label: 'Recusar',
                color: Colors.red,
                onTap: onReject,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.check,
                label: 'Aceitar',
                color: Colors.green,
                onTap: onAccept,
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

/// Botão com animação de scale ao pressionar. Usado para aceitar e recusar compartilhamentos.
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final scale = 1 - _controller.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _controller.reverse,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.8),
                widget.color.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
