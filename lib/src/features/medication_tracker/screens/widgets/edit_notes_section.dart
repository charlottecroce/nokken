// notes_section.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/shared_widgets.dart';
import '../../../../shared/theme/app_theme.dart';

class NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const NotesSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Notes',
      children: [
        TextFormField(
          controller: controller,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            hintText: 'Add any additional notes here',
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
