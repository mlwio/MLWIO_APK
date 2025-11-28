import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppCategories.categories.length,
        itemBuilder: (context, index) {
          final category = AppCategories.categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(category);
                }
              },
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(AppColors.textValue),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              selectedColor: const Color(AppColors.accentValue),
              backgroundColor: const Color(AppColors.cardValue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
