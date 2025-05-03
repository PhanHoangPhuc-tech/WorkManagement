import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final catVM = context.watch<CategoryViewModel>();
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final categories = catVM.categories;
    final filterOptions = ['Tất cả', ...categories.where((c) => c != 'Tất cả')];
    final bool categoriesStillLoading = catVM.isLoading && catVM.categories.isEmpty;

    final Color filterBarBorderColor = isDarkMode ? theme.dividerColor.withAlpha(51) : Colors.grey.shade300;
    final Color filterBarBackgroundColor = isDarkMode ? theme.colorScheme.surface : Colors.white;
    final Color chipSelectedBgColor = theme.primaryColor.withAlpha(isDarkMode ? 70 : 30);
    final Color chipUnselectedBgColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final Color chipSelectedTextColor = theme.primaryColor;
    final Color? chipUnselectedTextColor = theme.textTheme.bodySmall?.color;
    final BorderSide chipUnselectedBorder = BorderSide(color: filterBarBorderColor, width: 0.5);
    final BorderSide chipSelectedBorder = BorderSide(color: theme.primaryColor.withAlpha(150), width: 1);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filterBarBackgroundColor,
        border: Border(bottom: BorderSide(color: filterBarBorderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: categoriesStillLoading
                ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filterOptions.length,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final filterName = filterOptions[idx];
                      final filterValue = filterName == 'Tất cả' ? null : filterName;
                      final isSelected = taskVM.selectedCategoryFilter == filterValue;
                      return ChoiceChip(
                        label: Text(filterName),
                        selected: isSelected,
                        onSelected: (_) => taskVM.setCategoryFilter(filterValue),
                        selectedColor: chipSelectedBgColor,
                        backgroundColor: chipUnselectedBgColor,
                        labelStyle: TextStyle(fontSize: 13, color: isSelected ? chipSelectedTextColor : chipUnselectedTextColor, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                        side: isSelected ? chipSelectedBorder : chipUnselectedBorder,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}