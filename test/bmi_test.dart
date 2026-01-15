import 'package:flutter_test/flutter_test.dart';
import 'package:clinixai/utils/bmi.dart';

void main() {
  test('calculates BMI', () {
    final double bmi = calculateBmi(weightKg: 70, heightCm: 175);
    expect(bmi, closeTo(22.86, 0.01));
  });

  test('handles zero height', () {
    expect(calculateBmi(weightKg: 70, heightCm: 0), 0);
  });
}
