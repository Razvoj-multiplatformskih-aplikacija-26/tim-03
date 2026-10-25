import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../shortcuts.dart';
import '../widgets/order_detail_panel.dart';
import '../widgets/orders_list.dart';
import '../widgets/orders_table.dart';
import '../widgets/reason_dialog.dart';

/// The staff's main screen: every order of the center in a table, and the chosen one in a side panel. The screen only
/// draws the state of [OrderBoardBloc] and sends it events, from the mouse or from the keyboard.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _ordersFocus = FocusNode(debugLabel: 'orders');

  OrderBoardBloc get _bloc => context.read<OrderBoardBloc>();

  @override
  void dispose() {
    _ordersFocus.dispose();
    super.dispose();
  }

  ServiceOrder? get _selected => switch (_bloc.state) {
    OrderBoardLoaded(:final selected) => selected,
    OrderBoardLoading() || OrderBoardFailure() => null,
  };

  /// A shortcut works only for an action the domain allows on the selected order, and not while another is on its way.
  bool _selectedAllows(StaffAction action) {
    final state = _bloc.state;
    if (state is! OrderBoardLoaded || state.isBusy) return false;
    final selected = state.selected;
    return selected != null && state.actionsFor(selected).contains(action);
  }

  void _confirm(ServiceOrder order) => _bloc.add(OrderConfirmationRequested(order.id));

  /// A rejection cannot be undone, so it asks for confirmation and a reason first.
  Future<void> _reject(ServiceOrder order) async {
    final state = _bloc.state;
    final pet = state is OrderBoardLoaded ? state.board.petOf(order) : null;
    final reason = await askRejectionReason(
      context,
      orderLabel: '${order.service.label}${pet == null ? '' : ' za ljubimca ${pet.name}'}, ${periodLabel(order)}',
    );
    if (!mounted || reason == null) return;
    _bloc.add(OrderRejectionRequested(order.id, reason: reason));
  }

  void _select(ServiceOrder order) {
    _ordersFocus.requestFocus();
    _bloc.add(OrderBoardOrderSelected(order.id));
  }

  void _closePanel() {
    _bloc.add(const OrderBoardOrderSelected(null));
    _ordersFocus.requestFocus();
  }

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
    _bloc.add(const OrderBoardNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = _bloc;
    return Shortcuts(
      shortcuts: orderShortcuts(),
      child: Actions(
        actions: {
          MoveSelectionIntent: CallbackAction<MoveSelectionIntent>(
            onInvoke: (intent) {
              bloc.add(OrderBoardSelectionMoved(intent.steps));
              return null;
            },
          ),
          ClosePanelIntent: GuardedCallbackAction<ClosePanelIntent>(
            enabled: () => _selected != null,
            onInvoke: (_) {
              _closePanel();
              return null;
            },
          ),
          ConfirmSelectedIntent: GuardedCallbackAction<ConfirmSelectedIntent>(
            enabled: () => _selectedAllows(StaffAction.confirm),
            onInvoke: (_) {
              if (_selected case final order?) _confirm(order);
              return null;
            },
          ),
          RejectSelectedIntent: GuardedCallbackAction<RejectSelectedIntent>(
            enabled: () => _selectedAllows(StaffAction.reject),
            onInvoke: (_) {
              if (_selected case final order?) _reject(order);
              return null;
            },
          ),
        },
        child: Scaffold(
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
              OrderBoardLoaded() => _Board(
                state: state,
                ordersFocus: _ordersFocus,
                onSelect: _select,
                onClose: _closePanel,
                onConfirm: _confirm,
                onReject: _reject,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.state,
    required this.ordersFocus,
    required this.onSelect,
    required this.onClose,
    required this.onConfirm,
    required this.onReject,
  });

  final OrderBoardLoaded state;
  final FocusNode ordersFocus;
  final ValueChanged<ServiceOrder> onSelect;
  final VoidCallback onClose;
  final ValueChanged<ServiceOrder> onConfirm;
  final ValueChanged<ServiceOrder> onReject;

  @override
  Widget build(BuildContext context) {
    final selected = state.selected;
    final actions = selected == null ? const <StaffAction>{} : state.actionsFor(selected);
    final panel = selected == null
        ? null
        : OrderDetailPanel(
            order: selected,
            board: state.board,
            onClose: onClose,
            onConfirm: actions.contains(StaffAction.confirm) ? () => onConfirm(selected) : null,
            onReject: actions.contains(StaffAction.reject) ? () => onReject(selected) : null,
            busy: state.isBusy,
          );
    // The layout follows the width the screen gets. The selection lives in the bloc above this builder, so changing
    // the layout keeps it.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _tableFromWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OrdersList(
                  board: state.board,
                  rows: state.rows,
                  selectedId: state.selectedId,
                  focusNode: ordersFocus,
                  onSelect: onSelect,
                ),
              ),
              if (panel != null) ...[
                const Divider(height: 1),
                SizedBox(height: constraints.maxHeight / 2, child: panel),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OrdersTable(
                board: state.board,
                rows: state.rows,
                selectedId: state.selectedId,
                focusNode: ordersFocus,
                onSelect: onSelect,
              ),
            ),
            if (panel != null) ...[const VerticalDivider(width: 1), SizedBox(width: 360, child: panel)],
          ],
        );
      },
    );
  }
}

/// Below this width the table gives way to a list, and the side panel moves under it.
const _tableFromWidth = 900.0;
