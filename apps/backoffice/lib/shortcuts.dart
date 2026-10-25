import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// An action that works only while [enabled] says so; otherwise the key goes on as if there were no shortcut.
class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}

/// The arrow keys: one order down is 1, one order up is -1.
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

/// The keys of the orders screen. Ctrl+W, Ctrl+T, Ctrl+N and F5 stay with the browser, since the same build runs
/// there.
Map<ShortcutActivator, Intent> orderShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.arrowDown): const MoveSelectionIntent(1),
  const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveSelectionIntent(-1),
  const SingleActivator(LogicalKeyboardKey.escape): const ClosePanelIntent(),
  const SingleActivator(LogicalKeyboardKey.keyP): const ConfirmSelectedIntent(),
  const SingleActivator(LogicalKeyboardKey.keyO): const RejectSelectedIntent(),
};
