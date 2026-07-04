import 'package:flutter/material.dart';

/// Style input dùng chung cho màn Sign In / Sign Up (filled, bo góc, prefix icon)
/// — polish nhất quán trong Material 3 theme sẵn có.
InputDecoration authInputDecoration(String label, {IconData? icon, String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

/// Style nút CTA chính của màn auth (cao, bo góc).
final ButtonStyle authButtonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);
