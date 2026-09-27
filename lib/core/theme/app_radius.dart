import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 20.0;
  static const double extraLarge = 32.0;
  static const double circular = 100.0;

  static BorderRadius get smallBorderRadius => BorderRadius.circular(small);
  static BorderRadius get mediumBorderRadius => BorderRadius.circular(medium);
  static BorderRadius get largeBorderRadius => BorderRadius.circular(large);
  static BorderRadius get extraLargeBorderRadius =>
      BorderRadius.circular(extraLarge);
  static BorderRadius get circularBorderRadius =>
      BorderRadius.circular(circular);
}
