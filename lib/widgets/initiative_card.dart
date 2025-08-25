// lib/widgets/initiative_card.dart
import 'package:flutter/material.dart';
import '../models/initiative_model.dart';

class InitiativeCard extends StatelessWidget {
  final Initiative initiative;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool compact;

  const InitiativeCard({super.key, required this.initiative, this.onTap, this.onEdit, this.compact = false});

  String _dateRange() {
    final s = initiative.startDate?.toDate();
    final e = initiative.endDate?.toDate();
    if (s == null && e == null) return '';
    final sd = s != null ? s.toLocal().toString().split(' ').first : '';
    final ed = e != null ? e.toLocal().toString().split(' ').first : '';
    return [sd, ed].where((x) => x.isNotEmpty).join(' → ');
  }

  double? _progress() {
    final goal = initiative.goalAmount;
    final raised = (initiative.computedRaisedAmount ?? initiative.raisedAmount);
    if (goal == null || goal == 0 || raised == null) return null;
    final ratio = raised / goal;
    if (ratio.isNaN || ratio.isInfinite) return null;
    return ratio.clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final cat = initiative.category;
    final status = initiative.status;
    final dateRange = _dateRange();
    final progress = _progress();

    if (compact) {
      Widget thumb() {
        final hasImg = (initiative.coverImageUrl != null && initiative.coverImageUrl!.isNotEmpty);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 72,
            height: 72,
            child: hasImg
                ? Image.network(initiative.coverImageUrl!, fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    alignment: Alignment.center,
                    child: Text(
                      initiative.title.isNotEmpty ? initiative.title[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        );
      }

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap ?? onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                thumb(),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    initiative.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (onEdit != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    tooltip: 'Edit',
                                    onPressed: onEdit,
                                  ),
                              ],
                            ),
                            if ((initiative.description ?? '').isNotEmpty) ...[
                              Text(
                                initiative.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (cat != null && cat.isNotEmpty)
                                  Chip(
                                    label: Text(cat),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.grey.shade200,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (status.isNotEmpty)
                                  Chip(
                                    label: Text(status),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    side: BorderSide(color: Colors.blueGrey.shade200),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (dateRange.isNotEmpty)
                                  Chip(
                                    label: Text(dateRange),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.blue.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            if (progress != null) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Non-compact
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap ?? onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 90,
              width: double.infinity,
              child: initiative.coverImageUrl != null && initiative.coverImageUrl!.isNotEmpty
                  ? Image.network(initiative.coverImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      alignment: Alignment.center,
                      child: Text(
                        initiative.title.isNotEmpty ? initiative.title[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 40,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              initiative.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Edit',
                              onPressed: onEdit,
                            ),
                        ],
                      ),
                      if ((initiative.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          initiative.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (cat != null && cat.isNotEmpty)
                            Chip(
                              label: Text(cat),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          if (status.isNotEmpty)
                            Chip(
                              label: Text(status),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(color: Colors.blueGrey.shade200),
                            ),
                          if (dateRange.isNotEmpty)
                            Chip(
                              label: Text(dateRange),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.blue.shade50,
                            ),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}% of goal',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
