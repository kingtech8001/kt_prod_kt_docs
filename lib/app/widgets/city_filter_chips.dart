import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class CityFilterChips extends StatelessWidget {
  final String selectedCity;
  final ValueChanged<String> onCitySelected;
  final List<String>? customCities;

  const CityFilterChips({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
    this.customCities,
  });

  @override
  Widget build(BuildContext context) {
    final cities = customCities != null && customCities!.isNotEmpty
        ? ['All Cities', ...customCities!]
        : AppConstants.supportedCities;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = cities[index];
          final isSelected = selectedCity.toLowerCase() == city.toLowerCase();

          return InkWell(
            onTap: () => onCitySelected(city),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (city != 'All Cities') ...[
                    Icon(
                      Icons.location_city,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    city,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
