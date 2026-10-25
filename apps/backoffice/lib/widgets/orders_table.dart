import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

/// How wide each column is, in the order of the header.
const _columnFlex = [3, 2, 3, 3, 3, 3];

/// Every order of the center, one per row. A click or an arrow key selects an order; the selected row stands out and
/// stays in view. A frame around the table shows when it has the keyboard focus.
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
  void didUpdateWidget(OrdersTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  /// Scrolls only as far as needed to show the whole selected row, above or below.
  void _reveal() {
    final row = _selectedRow.currentContext;
    if (row == null || !row.mounted) return;
    Scrollable.ensureVisible(row, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    Scrollable.ensureVisible(row, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      child: ListenableBuilder(
        listenable: widget.focusNode,
        builder: (context, child) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: widget.focusNode.hasFocus ? scheme.primary : Colors.transparent, width: 2),
          ),
          child: child,
        ),
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

  /// The kennel for boarding, the member of staff for everything else, once the order is confirmed.
  String _assignment() {
    if (board.kennelOf(order) case final kennel?) return 'Boks ${kennel.label}';
    if (board.assigneeOf(order) case final person?) return person.name;
    return '—';
  }

  /// The hours of a visit, or the hand-over time and the nights of a stay.
  String _hours() {
    final period = order.period;
    return switch (order.service.visitLength) {
      null => '${formatTime(period.start)} · ${nightsLabel(nightsOf(period))}',
      _ => '${formatTime(period.start)}–${formatTime(period.end)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final start = order.period.start;
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
                  Text('${capitalize(formatWeekdayShort(start))} ${formatShortDate(start)}'),
                  Text(_hours(), style: muted),
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
