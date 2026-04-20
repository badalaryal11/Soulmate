import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: colorScheme.primary.withValues(alpha: 0.14),
      checkmarkColor: colorScheme.primary,
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
      backgroundColor: colorScheme.surface,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected
            ? colorScheme.primary
            : theme.textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppThemeTokens.spaceSm,
        vertical: AppThemeTokens.spaceXs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
      ),
    );
  }
}
