import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/category.dart';

class CategoryFilterChip extends StatelessWidget {
  final ItemCategory? category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryFilterChip({
    super.key,
    required this.category,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    return ChoiceChip(
      label: Text(label),
      avatar: category == null
          ? null
          : Icon(category!.icon, size: 18, color: fg),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.leaf,
      showCheckmark: false,
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      side: BorderSide(color: selected ? AppColors.leaf : AppColors.line),
    );
  }
}
