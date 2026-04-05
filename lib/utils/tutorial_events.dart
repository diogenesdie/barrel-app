// =============================================================================
// tutorial_events.dart
//
// Canal de eventos global para coordenar a exibição de tutoriais coach mark
// entre widgets que não compartilham a mesma árvore de widgets.
//
// Valores possíveis: "show_add_device" | null
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

/// Notifier global para acionar tutoriais coach mark entre telas.
///
/// Definir um valor dispara o tutorial correspondente em qualquer widget
/// que esteja escutando via [ValueListenableBuilder] ou [addListener].
final tutorialNotifier = ValueNotifier<String?>(null);
