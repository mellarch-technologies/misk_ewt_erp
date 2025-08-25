// lib/widgets/pagination_bar.dart
import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int total;
  final int pageSize;
  final int pageIndex; // 0-based
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.total,
    this.pageSize = 20,
    required this.pageIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pageCount = (total / pageSize).ceil();
    final clampedPage = pageIndex.clamp(0, pageCount > 0 ? pageCount - 1 : 0);
    final start = total == 0 ? 0 : clampedPage * pageSize + 1;
    final end = total == 0 ? 0 : (clampedPage + 1) * pageSize > total ? total : (clampedPage + 1) * pageSize;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of $total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: clampedPage > 0 ? () => onPageChanged(clampedPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${clampedPage + 1}/$pageCount', style: Theme.of(context).textTheme.bodySmall),
          IconButton(
            tooltip: 'Next page',
            onPressed: (clampedPage + 1) < pageCount ? () => onPageChanged(clampedPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

