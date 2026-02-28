import 'package:flutter/material.dart';

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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFFFE3C72).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFFFE3C72),
      labelStyle: TextStyle(
        color: isSelected
            ? const Color(0xFFFE3C72)
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFE3C72) : Colors.transparent,
        ),
      ),
    );
  }
}
