import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../widgets/order_detail_panel.dart';
import '../widgets/orders_table.dart';
import '../widgets/reason_dialog.dart';

/// The staff's main screen: every order of the center in a table, and the chosen one in a side panel. The screen only
/// draws the state of [OrderBoardBloc] and sends it events.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  /// Shown once, then acknowledged so it is not shown again.
  void _showNotice(BuildContext context, OrderBoardNotice notice) {
    final message = switch (notice) {
      StaffActionSucceeded(:final order) => switch (order.status) {
        Confirmed() => 'Nalog je potvrđen.',
        Rejected() => 'Nalog je odbijen.',
        Pending() || InProgress() || ReadyForPickup() || Completed() || Cancelled() => 'Nalog je sačuvan.',
      },
      StaffActionRejected(:final error) => error.message,
      StaffActionFailed() => 'Promena nije sačuvana. Proverite vezu i pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    context.read<OrderBoardBloc>().add(const OrderBoardNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<OrderBoardBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nalozi centra'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${bloc.staff.name} · ${bloc.staff.role.label}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: BlocConsumer<OrderBoardBloc, OrderBoardState>(
        listenWhen: (previous, current) => current is OrderBoardLoaded && current.notice != null,
        listener: (context, state) => _showNotice(context, (state as OrderBoardLoaded).notice!),
        builder: (context, state) => switch (state) {
          OrderBoardLoading() => Center(
            child: Semantics(label: 'Učitavanje naloga', child: const CircularProgressIndicator()),
          ),
          OrderBoardFailure() => Center(
            child: FailureView(title: 'Nalozi nisu učitani.', onRetry: () => bloc.add(const OrderBoardRequested())),
          ),
          OrderBoardLoaded(isEmpty: true) => const Center(
            child: EmptyView(title: 'Nema naloga.', message: 'Nalozi vlasnika pojaviće se ovde.'),
          ),
          OrderBoardLoaded() => _Board(state: state),
        },
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state});

  final OrderBoardLoaded state;

  /// A rejection cannot be undone, so it asks for confirmation and a reason first.
  Future<void> _reject(BuildContext context, ServiceOrder order) async {
    final bloc = context.read<OrderBoardBloc>();
    final pet = state.board.petOf(order);
    final reason = await askRejectionReason(
      context,
      orderLabel: '${order.service.label}${pet == null ? '' : ' za ljubimca ${pet.name}'}, ${periodLabel(order)}',
    );
    if (reason == null) return;
    bloc.add(OrderRejectionRequested(order.id, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderBoardBloc>();
    final selected = state.selected;
    final actions = selected == null ? const <StaffAction>{} : state.actionsFor(selected);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: OrdersTable(
            board: state.board,
            rows: state.rows,
            selectedId: state.selectedId,
            onSelect: (order) => bloc.add(OrderBoardOrderSelected(order.id)),
          ),
        ),
        if (selected != null) ...[
          const VerticalDivider(width: 1),
          SizedBox(
            width: 360,
            child: OrderDetailPanel(
              order: selected,
              board: state.board,
              onClose: () => bloc.add(const OrderBoardOrderSelected(null)),
              onConfirm: actions.contains(StaffAction.confirm)
                  ? () => bloc.add(OrderConfirmationRequested(selected.id))
                  : null,
              onReject: actions.contains(StaffAction.reject) ? () => _reject(context, selected) : null,
              busy: state.isBusy,
            ),
          ),
        ],
      ],
    );
  }
}
