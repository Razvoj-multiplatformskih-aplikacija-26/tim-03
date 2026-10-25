import 'package:flutter/material.dart';

/// Nothing to show yet, with a word on what to do about it.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.message, this.icon = Icons.pets});

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      _StateLayout(icon: icon, iconColor: Theme.of(context).colorScheme.primary, title: title, message: message);
}

/// The data could not be loaded; the button asks for it again.
class FailureView extends StatelessWidget {
  const FailureView({
    super.key,
    required this.onRetry,
    this.title = 'Podaci nisu učitani.',
    this.message = 'Proverite vezu sa internetom i pokušajte ponovo.',
  });

  final VoidCallback onRetry;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) => _StateLayout(
    icon: Icons.cloud_off_outlined,
    iconColor: Theme.of(context).colorScheme.error,
    title: title,
    message: message,
    action: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Pokušaj ponovo')),
  );
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({required this.icon, required this.iconColor, required this.title, this.message, this.action});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = this.message;
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 96, color: iconColor),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 24), action],
        ],
      ),
    );
  }
}
