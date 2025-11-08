import 'package:flutter/material.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class InputDecorations {
  static InputDecoration inputDecoration({
    required String hintText,
    required String labelText,
    required Icon icono,
  }) {
    return InputDecoration(
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.secondary),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      hintText: hintText,
      labelText: labelText,
      prefixIcon: icono,
    );
  }
}
