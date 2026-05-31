import 'package:flutter/material.dart';
import '../models/filter_option.dart';

ColorFilter filterMatrix(FilterType filter) {
  switch (filter) {
    case FilterType.auto:
      return const ColorFilter.matrix([
        1.06, 0, 0, 0, -7.65,
        0, 1.06, 0, 0, -7.65,
        0, 0, 1.06, 0, -7.65,
        0, 0, 0, 1, 0,
      ]);
    case FilterType.magic:
      return const ColorFilter.matrix([
        1.284, 0, 0, 0, -25.5,
        0, 1.284, 0, 0, -25.5,
        0, 0, 1.284, 0, -25.5,
        0, 0, 0, 1, 0,
      ]);
    case FilterType.gray:
      return const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case FilterType.bw:
      return const ColorFilter.matrix([
        0.404, 1.359, 0.137, 0, -114.75,
        0.404, 1.359, 0.137, 0, -114.75,
        0.404, 1.359, 0.137, 0, -114.75,
        0, 0, 0, 1, 0,
      ]);
    case FilterType.original:
      return const ColorFilter.matrix([
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ]);
  }
}
