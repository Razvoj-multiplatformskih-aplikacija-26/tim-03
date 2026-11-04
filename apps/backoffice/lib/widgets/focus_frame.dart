import 'package:flutter/material.dart';

class FocusFrame extends StatelessWidget {
  const FocusFrame({super.key, required this.focusNode, required this.child});

  final FocusNode focusNode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, child) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: focusNode.hasFocus ? scheme.primary : Colors.transparent, width: 2),
          ),
          child: child,
        ),
        child: child,
      ),
    );
  }
}
