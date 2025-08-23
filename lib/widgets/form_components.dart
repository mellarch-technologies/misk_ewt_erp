import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StickyActionBar extends StatelessWidget {
  final List<Widget> actions;
  final bool isSticky;
  final Color? backgroundColor;

  const StickyActionBar({
    super.key,
    required this.actions,
    this.isSticky = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        boxShadow: isSticky
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: MiskTheme.spacingMedium,
          right: MiskTheme.spacingMedium,
          top: MiskTheme.spacingMedium,
          bottom: MiskTheme.spacingMedium + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: actions.map((action) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: action,
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final bool isRequired;

  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MiskTheme.spacingMedium,
            vertical: MiskTheme.spacingSmall,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: MiskTheme.miskDarkGreen,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.weightSemiBold,
                  color: MiskTheme.miskDarkGreen,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: SemanticColors.dangerRed,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MiskTheme.spacingMedium),
          margin: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
            border: Border.all(
              color: MiskTheme.miskLightGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(height: MiskTheme.spacingMedium),
      ],
    );
  }
}

class CurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool isRequired;
  final String? errorText;
  final VoidCallback? onChanged;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.isRequired = false,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        prefixText: '₹ ',
        prefixStyle: TextStyle(
          color: MiskTheme.miskDarkGreen,
          fontWeight: FontWeight.w600,
        ),
        helperText: helperText,
        errorText: errorText,
        helperMaxLines: 2,
      ),
      validator: (value) {
        if (isRequired && (value?.trim().isEmpty ?? true)) {
          return 'This field is required';
        }
        if (value?.trim().isNotEmpty ?? false) {
          final parsed = double.tryParse(value!.replaceAll(',', ''));
          if (parsed == null || parsed < 0) {
            return 'Please enter a valid amount';
          }
        }
        return null;
      },
      onChanged: (value) {
        // Auto-format with thousand separators
        if (value.isNotEmpty) {
          final parsed = double.tryParse(value.replaceAll(',', ''));
          if (parsed != null) {
            final formatted = _formatCurrency(parsed);
            if (formatted != value) {
              controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          }
        }
        onChanged?.call();
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final amountStr = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    return amountStr.replaceAllMapped(formatter, (Match match) => '${match[1]},');
  }
}

class DateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool noEndDate;
  final String startLabel;
  final String endLabel;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(bool) onNoEndDateChanged;

  const DateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    this.noEndDate = false,
    this.startLabel = 'Start Date',
    this.endLabel = 'End Date',
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onNoEndDateChanged,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    widget.onStartDateChanged(picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  widget.startDate != null
                      ? '${widget.startDate!.day}/${widget.startDate!.month}/${widget.startDate!.year}'
                      : widget.startLabel,
                ),
              ),
            ),
            const SizedBox(width: MiskTheme.spacingMedium),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.noEndDate
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: widget.endDate ?? 
                              (widget.startDate?.add(const Duration(days: 30)) ?? DateTime.now()),
                          firstDate: widget.startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          widget.onEndDateChanged(picked);
                        }
                      },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  widget.noEndDate
                      ? 'No end date'
                      : (widget.endDate != null
                          ? '${widget.endDate!.day}/${widget.endDate!.month}/${widget.endDate!.year}'
                          : widget.endLabel),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MiskTheme.spacingSmall),
        CheckboxListTile(
          title: const Text('No end date'),
          value: widget.noEndDate,
          onChanged: (value) {
            widget.onNoEndDateChanged(value ?? false);
            if (value == true) {
              widget.onEndDateChanged(null);
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class MediaUploadGrid extends StatelessWidget {
  final List<MediaUploadTile> tiles;
  final int crossAxisCount;

  const MediaUploadGrid({
    super.key,
    required this.tiles,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: MiskTheme.spacingMedium,
      mainAxisSpacing: MiskTheme.spacingMedium,
      children: tiles,
    );
  }
}

class MediaUploadTile extends StatelessWidget {
  final String title;
  final String? currentFileName;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;
  final IconData icon;
  final bool isLoading;

  const MediaUploadTile({
    super.key,
    required this.title,
    this.currentFileName,
    required this.onUpload,
    this.onRemove,
    this.icon = Icons.upload,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: MiskTheme.miskLightGreen.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const CircularProgressIndicator()
          else
            Icon(
              icon,
              size: 32,
              color: MiskTheme.miskDarkGreen,
            ),
          const SizedBox(height: MiskTheme.spacingSmall),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentFileName != null) ...[
            const SizedBox(height: 4),
            Text(
              currentFileName!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: MiskTheme.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: isLoading ? null : onUpload,
                child: Text(currentFileName != null ? 'Replace' : 'Upload'),
              ),
              if (currentFileName != null && onRemove != null)
                TextButton(
                  onPressed: isLoading ? null : onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: SemanticColors.dangerRed,
                  ),
                  child: const Text('Remove'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
