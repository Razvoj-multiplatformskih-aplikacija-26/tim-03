import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'focus_frame.dart';
import 'order_labels.dart';

/// The same orders as the table, one card per order, for a narrow window. The selection comes from the bloc, so the
/// order selected in the table is selected here too and in view.
class OrdersList extends StatefulWidget {
  const OrdersList({
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
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  final _selectedItem = GlobalKey();

  /// A narrower window builds the list anew; it opens on the order that was selected in the table.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void didUpdateWidget(OrdersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  /// Scrolls only as far as needed to show the whole selected card, above or below.
  void _reveal() {
    final item = _selectedItem.currentContext;
    if (item == null || !item.mounted) return;
    Scrollable.ensureVisible(item, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    Scrollable.ensureVisible(item, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
  }

  @override
  Widget build(BuildContext context) {
    return FocusFrame(
      focusNode: widget.focusNode,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final order in widget.rows) ...[
              KeyedSubtree(
                key: order.id == widget.selectedId ? _selectedItem : ValueKey(order.id),
                child: _OrderItem(
                  order: order,
                  board: widget.board,
                  selected: order.id == widget.selectedId,
                  onTap: () => widget.onSelect(order),
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({required this.order, required this.board, required this.selected, required this.onTap});

  final ServiceOrder order;
  final CenterBoard board;
  final bool selected;
  final VoidCallback onTap;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ServiceAvatar(service: order.service, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${board.petOf(order)?.name ?? '—'} · ${order.service.label}',
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('${orderDayLabel(order)} · ${orderHoursLabel(order)}', style: muted),
                      Text(board.ownerOf(order)?.name ?? '—', style: muted, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: order.status, service: order.service),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
