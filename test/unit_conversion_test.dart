import 'package:flutter_test/flutter_test.dart';
import 'package:clinixai/utils/unit_conversion.dart';

void main() {
  test('cm to feet and back', () {
    final double feet = cmToFeet(30.48);
    expect(feet, closeTo(1.0, 0.001));
    expect(feetToCm(1.0), closeTo(30.48, 0.001));
  });

  test('kg to lbs and back', () {
    final double lbs = kgToLbs(1);
    expect(lbs, closeTo(2.20462, 0.0001));
    expect(lbsToKg(2.20462), closeTo(1.0, 0.0001));
  });
}
