import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../widgets/order_detail_panel.dart';
import '../widgets/orders_table.dart';

/// The staff's main screen: every order of the center in a table, and the chosen one in a side panel. The screen only
/// draws the state of [OrderBoardBloc] and sends it events.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

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
      body: BlocBuilder<OrderBoardBloc, OrderBoardState>(
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

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderBoardBloc>();
    final selected = state.selected;
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
            ),
          ),
        ],
      ],
    );
  }
}
