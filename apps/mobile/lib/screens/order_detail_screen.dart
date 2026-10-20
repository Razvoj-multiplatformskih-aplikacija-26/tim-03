import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../text/domain_errors.dart';
import '../text/serbian.dart';
import '../widgets/service_avatar.dart';
import '../widgets/status_badge.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.id});

  final OrderId id;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fakeOrders,
      builder: (context, _) {
        final order = fakeOrders.byId(id);
        if (order == null || !AccessPolicy.canView(currentOwner, order)) return const _NotFound();
        return _DetailBody(order: order);
      },
    );
  }
}

/// Asks for confirmation, then cancels through the domain. Returns the text for the snack bar, or null if the owner
/// changed their mind.
Future<String?> confirmAndCancel(BuildContext context, ServiceOrder order) async {
  final pet = petById(order.petId);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Otkazati nalog?'),
      content: Text(
        '${order.service.label}${pet == null ? '' : ' za ljubimca ${pet.name}'}, ${periodLabel(order)}. '
        'Otkazivanje ne može da se poništi.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Da, otkaži')),
      ],
    ),
  );
  if (confirmed != true) return null;
  final result = cancelOrder(order, by: currentOwner, now: DateTime.now(), reason: 'Otkazano u aplikaciji.');
  switch (result) {
    case Success(:final value):
      fakeOrders.replace(value);
      return 'Nalog je otkazan.';
    case Failure(:final error):
      return error.message;
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.order});

  final ServiceOrder order;

  Future<void> _cancel(BuildContext context) async {
    final message = await confirmAndCancel(context, order);
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _staffName(UserId id) => staffById(id)?.name ?? id.value;

  List<_DetailRow> _periodRows() {
    final period = order.period;
    return switch (order.service.visitLength) {
      null => [
        _DetailRow(icon: Icons.login, label: 'Predaja', value: capitalize(formatDateAndTime(period.start))),
        _DetailRow(icon: Icons.logout, label: 'Preuzimanje', value: capitalize(formatDateAndTime(period.end))),
        _DetailRow(icon: Icons.nights_stay_outlined, label: 'Boravak', value: nightsLabel(nightsOf(period))),
      ],
      final length => [
        _DetailRow(
          icon: Icons.event_outlined,
          label: 'Termin',
          value: '${capitalize(formatDate(period.start))}, ${formatTime(period.start)}–${formatTime(period.end)}',
        ),
        _DetailRow(icon: Icons.schedule_outlined, label: 'Trajanje', value: durationLabel(length)),
      ],
    };
  }

  List<_DetailRow> _assignmentRows() {
    final kennelId = order.kennelId;
    final assigneeId = order.assigneeId;
    return [
      if (kennelId != null)
        _DetailRow(
          icon: Icons.night_shelter_outlined,
          label: 'Boks',
          value: kennelById(kennelId)?.label ?? kennelId.value,
        ),
      if (assigneeId != null)
        _DetailRow(
          icon: Icons.badge_outlined,
          label: order.service.performer?.label ?? 'Izvršilac',
          value: _staffName(assigneeId),
        ),
    ];
  }

  List<_DetailRow> _statusRows() {
    final isWalk = order.service == ServiceType.walk;
    return switch (order.status) {
      Pending() => const [],
      Confirmed(:final confirmedBy, :final at) => [
        _DetailRow(
          icon: Icons.check_circle_outline,
          label: 'Potvrđen',
          value: '${capitalize(formatDateAndTime(at))} · ${_staffName(confirmedBy)}',
        ),
      ],
      InProgress(:final receivedBy, :final at) => [
        _DetailRow(
          icon: Icons.pets,
          label: isWalk ? 'Šetač preuzeo ljubimca' : 'Ljubimac primljen',
          value: '${capitalize(formatDateAndTime(at))} · ${_staffName(receivedBy)}',
        ),
      ],
      ReadyForPickup(:final at) => [
        _DetailRow(
          icon: Icons.home_outlined,
          label: isWalk ? 'Vraćen vlasniku' : 'Spreman za preuzimanje',
          value: capitalize(formatDateAndTime(at)),
        ),
      ],
      Completed(:final at) => [
        _DetailRow(icon: Icons.task_alt, label: 'Završen', value: capitalize(formatDateAndTime(at))),
      ],
      Rejected(:final reason, :final at) => [
        _DetailRow(
          icon: Icons.block,
          label: 'Odbijen',
          value: reason.isEmpty ? capitalize(formatDateAndTime(at)) : reason,
        ),
      ],
      Cancelled(:final reason, :final at) => [
        _DetailRow(
          icon: Icons.cancel_outlined,
          label: 'Otkazan',
          value: reason.isEmpty ? capitalize(formatDateAndTime(at)) : reason,
        ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pet = petById(order.petId);
    final note = order.note;
    final rows = [
      if (pet != null)
        _DetailRow(icon: Icons.pets_outlined, label: 'Ljubimac', value: '${pet.name} · ${pet.description}'),
      ..._periodRows(),
      ..._assignmentRows(),
      if (note != null) _DetailRow(icon: Icons.notes_outlined, label: 'Napomena', value: note.text),
      ..._statusRows(),
      _DetailRow(
        icon: Icons.edit_calendar_outlined,
        label: 'Poslat',
        value: capitalize(formatDateAndTime(order.createdAt)),
      ),
    ];
    // The domain decides whether the owner may cancel; the screen only shows the answer.
    final cancelCheck = cancelOrder(order, by: currentOwner, now: DateTime.now());
    final cancelBar = switch (cancelCheck) {
      Success() => _CancelBar(onCancel: () => _cancel(context)),
      Failure(error: final CancellationTooLate error) => _CancelBar(onCancel: null, hint: error.message),
      Failure() => null,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Nalog')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceAvatar(service: order.service, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(order.service.label, style: theme.textTheme.headlineMedium),
                        ),
                        if (pet != null) ...[
                          const SizedBox(height: 2),
                          Text(pet.name, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 10),
                        StatusBadge(status: order.status, service: order.service),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    for (final (index, row) in rows.indexed) ...[
                      if (index > 0) const Divider(indent: 16, endIndent: 16),
                      row,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: cancelBar,
    );
  }
}

class _CancelBar extends StatelessWidget {
  const _CancelBar({required this.onCancel, this.hint});

  final VoidCallback? onCancel;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = this.hint;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hint != null) ...[
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close),
                label: const Text('Otkaži nalog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: theme.textTheme.titleMedium),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nalog')),
      body: Center(child: Text(const NotFound().message, style: Theme.of(context).textTheme.titleLarge)),
    );
  }
}
