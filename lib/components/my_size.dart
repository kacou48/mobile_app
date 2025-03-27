import 'package:flutter/material.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double defaultSize;
  static late Orientation orientation;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
  }
}

// Obtenez une hauteur proportionnelle par rapport à la taille de l'écran
double getProportionateScreenHeight(double inputHeight) {
  double screenHeight = SizeConfig.screenHeight;
  // 812 est la hauteur de référence utilisée par le designer
  return (inputHeight / 812.0) * screenHeight;
}

// Obtenez une largeur proportionnelle par rapport à la taille de l'écran
double getProportionateScreenWidth(double inputWidth) {
  double screenWidth = SizeConfig.screenWidth;
  // 375 est la largeur de référence utilisée par le designer
  return (inputWidth / 375.0) * screenWidth;
}
