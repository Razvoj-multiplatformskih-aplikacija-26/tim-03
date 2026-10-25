import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

/// The selected order in detail, next to the table.
class OrderDetailPanel extends StatelessWidget {
  const OrderDetailPanel({super.key, required this.order, required this.board, required this.onClose});

  final ServiceOrder order;
  final CenterBoard board;
  final VoidCallback onClose;

  String _statusDetail() {
    final isWalk = order.service == ServiceType.walk;
    return switch (order.status) {
      Pending() => 'Čeka potvrdu osoblja.',
      Confirmed(:final at) => 'Potvrđen ${formatDateAndTime(at)}.',
      InProgress(:final at) =>
        isWalk
            ? 'Šetač je preuzeo ljubimca ${formatDateAndTime(at)}.'
            : 'Ljubimac je primljen ${formatDateAndTime(at)}.',
      ReadyForPickup(:final at) =>
        isWalk ? 'Vraćen vlasniku ${formatDateAndTime(at)}.' : 'Spreman za preuzimanje od ${formatDateAndTime(at)}.',
      Completed(:final at) => 'Završen ${formatDateAndTime(at)}.',
      Rejected(:final reason, :final at) =>
        'Odbijen ${formatDateAndTime(at)}.${reason.isEmpty ? '' : ' Razlog: $reason'}',
      Cancelled(:final reason, :final at) =>
        'Otkazan ${formatDateAndTime(at)}.${reason.isEmpty ? '' : ' Razlog: $reason'}',
    };
  }

  List<Widget> _periodFields() {
    final period = order.period;
    return switch (order.service.visitLength) {
      null => [
        _Field(label: 'Predaja', value: capitalize(formatDateAndTime(period.start))),
        _Field(label: 'Preuzimanje', value: capitalize(formatDateAndTime(period.end))),
        _Field(label: 'Boravak', value: nightsLabel(nightsOf(period))),
      ],
      final length => [
        _Field(label: 'Termin', value: periodLabel(order)),
        _Field(label: 'Trajanje', value: durationLabel(length)),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final pet = board.petOf(order);
    final kennel = board.kennelOf(order);
    final assignee = board.assigneeOf(order);
    final note = order.note;
    return Semantics(
      container: true,
      label: 'Detalj naloga',
      child: Material(
        color: scheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  ServiceAvatar(service: order.service),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(header: true, child: Text(order.service.label, style: theme.textTheme.titleLarge)),
                  ),
                  IconButton(tooltip: 'Zatvori detalj', onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(status: order.status, service: order.service),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusDetail(), style: muted),
                    const SizedBox(height: 20),
                    _Field(label: 'Ljubimac', value: pet == null ? 'Nepoznat' : '${pet.name} · ${pet.description}'),
                    _Field(label: 'Vlasnik', value: board.ownerOf(order)?.name ?? 'Nepoznat'),
                    ..._periodFields(),
                    if (kennel != null) _Field(label: 'Boks', value: kennel.label),
                    if (assignee != null)
                      _Field(label: order.service.performer?.label ?? 'Izvršilac', value: assignee.name),
                    if (note != null) _Field(label: 'Napomena', value: note.text),
                    _Field(label: 'Poslat', value: capitalize(formatDateAndTime(order.createdAt))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
