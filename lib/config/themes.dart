import 'package:flutter/material.dart';

class AppTextStyles {
  // Couleurs utilisées
  static const Color black = Colors.black;
  static const Color darkGrey = Color(0xFF333333);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFF999999);

  // Styles de texte
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontFamily: "Bold",
    fontWeight: FontWeight.w800,
    color: black,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 30,
    fontFamily: "Bold",
    fontWeight: FontWeight.w600,
    color: darkGrey,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontFamily: "Bold",
    fontWeight: FontWeight.w600,
    color: grey,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontFamily: "Regular",
    fontWeight: FontWeight.w400,
    color: lightGrey,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontFamily: "Regular",
    fontWeight: FontWeight.w400,
    color: grey,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontFamily: "Regular",
    fontWeight: FontWeight.w300,
    color: lightGrey,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontFamily: "Regular",
    fontWeight: FontWeight.w400,
    color: darkGrey,
    height: 1.5,
  );
}

final ThemeData lightTheme = ThemeData(
  textTheme: const TextTheme(
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    bodyLarge: AppTextStyles.bodyText,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  ),
);
