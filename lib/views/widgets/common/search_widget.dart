import 'package:flutter/material.dart';
import 'package:hhmmobile/app/theme/app_colors.dart';
import 'package:hhmmobile/app/theme/app_dimens.dart';

class SearchWidget extends StatelessWidget {
  const SearchWidget({super.key, required this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          color: Colors.white,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: Text(
                'Search Anything?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
