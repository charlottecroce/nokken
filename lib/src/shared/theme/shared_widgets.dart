// lib/src/common/ui_constants.dart
import 'package:flutter/material.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

class SharedWidgets {
  static Widget verticalSpace([double height = AppTheme.spacing]) {
    return SizedBox(height: height);
  }

  static Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium,
      ),
    );
  }

  static Widget basicCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: AppTheme.standardCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleMedium),
            verticalSpace(AppTheme.cardPadding),
            ...children,
          ],
        ),
      ),
    );
  }
}
