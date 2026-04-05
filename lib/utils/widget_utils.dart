// =============================================================================
// widget_utils.dart
//
// Utilitário para notificar o sistema operacional sobre atualizações no
// home screen widget (widget de tela inicial).
// Chamado sempre que dispositivos favoritos são alterados ou a sessão muda.
// =============================================================================

// Terceiros
import 'package:home_widget/home_widget.dart';

/// Notifica o sistema operacional para re-renderizar o home screen widget.
///
/// Deve ser chamado após qualquer alteração em dispositivos favoritos
/// ou após login/logout para manter o widget atualizado.
Future<void> updateWidget() async {
  await HomeWidget.updateWidget(
    name: 'DeviceActionWidget',
    iOSName: 'DeviceActionWidget',
  );
}
