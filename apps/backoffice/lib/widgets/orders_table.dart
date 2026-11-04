import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'focus_frame.dart';
import 'order_labels.dart';

const _columnFlex = [3, 2, 3, 3, 3, 3];

class OrdersTable extends StatefulWidget {
  const OrdersTable({
    super.key,
    required this.board,
    required this.rows,
    required this.selectedId,
    required this.focusNode,
    required this.onSelect,
  });

  final CenterBoard board;
  final List<ServiceOrder> rows;
  final OrderId? selectedId;
  final FocusNode focusNode;
  final ValueChanged<ServiceOrder> onSelect;

  @override
  State<OrdersTable> createState() => _OrdersTableState();
}

class _OrdersTableState extends State<OrdersTable> {
  final _selectedRow = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void didUpdateWidget(OrdersTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal() {
    final row = _selectedRow.currentContext;
    if (row == null || !row.mounted) return;
    Scrollable.ensureVisible(row, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    Scrollable.ensureVisible(row, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
  }

  @override
  Widget build(BuildContext context) {
    return FocusFrame(
      focusNode: widget.focusNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderRow(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final order in widget.rows)
                    KeyedSubtree(
                      key: order.id == widget.selectedId ? _selectedRow : ValueKey(order.id),
                      child: _OrderRow(
                        order: order,
                        board: widget.board,
                        selected: order.id == widget.selectedId,
                        onTap: () => widget.onSelect(order),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          for (final (index, child) in children.indexed)
            Expanded(
              flex: _columnFlex[index],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Align(alignment: Alignment.centerLeft, child: child),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Semantics(
      header: true,
      child: _Cells(
        children: [
          for (final label in ['Termin', 'Ljubimac', 'Vlasnik', 'Usluga', 'Boks / izvršilac', 'Stanje'])
            Text(label, style: style, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.board, required this.selected, required this.onTap});

  final ServiceOrder order;
  final CenterBoard board;
  final bool selected;
  final VoidCallback onTap;

  String _assignment() {
    if (board.kennelOf(order) case final kennel?) return 'Boks ${kennel.label}';
    if (board.assigneeOf(order) case final person?) return person.name;
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          selected: selected,
          child: _Cells(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderDayLabel(order)),
                  Text(orderHoursLabel(order), style: muted),
                ],
              ),
              Text(board.petOf(order)?.name ?? '—', overflow: TextOverflow.ellipsis),
              Text(board.ownerOf(order)?.name ?? '—', overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Icon(serviceIcon(order.service), size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Flexible(child: Text(order.service.label, overflow: TextOverflow.ellipsis)),
                ],
              ),
              Text(_assignment(), overflow: TextOverflow.ellipsis),
              StatusBadge(status: order.status, service: order.service),
            ],
          ),
        ),
      ),
    );
  }
}
