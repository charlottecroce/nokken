//
//  shared_widgets.dart
//  Reusable UI components
//
import 'package:flutter/material.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

class SharedWidgets {
  /// Creates a vertical spacer with customizable height
  /// Default height is the standard spacing value from AppTheme
  static Widget verticalSpace([double height = AppTheme.spacing]) {
    return SizedBox(height: height);
  }

  static Widget horizontalSpace([double width = AppTheme.spacing]) {
    return SizedBox(
      width: width,
    );
  }

  /// Builds a section header with standardized styling
  static Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium,
      ),
    );
  }

  /// Creates a standardized card with title and content
  /// Used for displaying grouped information throughout the app
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
