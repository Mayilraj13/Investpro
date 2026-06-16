import 'package:flutter/material.dart';

class AppUtils {
  AppUtils._();

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static BorderRadiusGeometry defaultBorderRadius = BorderRadius.circular(12);
  static BorderRadiusGeometry cardBorderRadius = BorderRadius.circular(16);

  static EdgeInsets screenPadding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  static EdgeInsets cardPadding = const EdgeInsets.all(16);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static SizedBox verticalSpace(double height) => SizedBox(height: height);
  static SizedBox horizontalSpace(double width) => SizedBox(width: width);
}

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static Curve defaultCurve = Curves.easeInOut;
  static Curve bounceCurve = Curves.elasticOut;
}
