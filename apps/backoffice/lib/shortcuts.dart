import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}

class MoveSelectionIntent extends Intent {
  const MoveSelectionIntent(this.steps);

  final int steps;
}

class ClosePanelIntent extends Intent {
  const ClosePanelIntent();
}

class ConfirmSelectedIntent extends Intent {
  const ConfirmSelectedIntent();
}

class RejectSelectedIntent extends Intent {
  const RejectSelectedIntent();
}

Map<ShortcutActivator, Intent> orderShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.arrowDown): const MoveSelectionIntent(1),
  const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveSelectionIntent(-1),
  const SingleActivator(LogicalKeyboardKey.escape): const ClosePanelIntent(),
  const SingleActivator(LogicalKeyboardKey.keyP): const ConfirmSelectedIntent(),
  const SingleActivator(LogicalKeyboardKey.keyO): const RejectSelectedIntent(),
};
