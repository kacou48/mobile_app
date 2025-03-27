import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TextComponents extends StatelessWidget {
  Color color;
  double txtSize;
  FontWeight fw;
  TextAlign textAlign;
  String txt;
  String family;

  TextComponents({
    super.key,
    required this.txt,
    this.color = Colors.black,
    this.fw = FontWeight.normal,
    this.txtSize = 16,
    this.textAlign = TextAlign.center,
    this.family = "Regular",
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      txt,
      style: TextStyle(
        fontFamily: family,
        color: color,
        fontSize: txtSize,
        fontWeight: fw,
      ),
      textAlign: textAlign,
    );
  }
}
