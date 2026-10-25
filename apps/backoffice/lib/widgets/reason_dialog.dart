import 'package:flutter/material.dart';

/// Asks why an order is rejected, since a rejection cannot be undone. Returns the reason, or null if staff change
/// their mind.
Future<String?> askRejectionReason(BuildContext context, {required String orderLabel}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(orderLabel: orderLabel),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.orderLabel});

  final String orderLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _reject() => Navigator.pop(context, _reason.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odbiti nalog?'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.orderLabel}. Odbijanje ne može da se poništi; vlasnik vidi razlog.'),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Razlog', hintText: 'Na primer: nema mesta u tom periodu.'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(onPressed: _reject, child: const Text('Odbij nalog')),
      ],
    );
  }
}
