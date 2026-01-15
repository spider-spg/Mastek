double calculateBmi({required double weightKg, required double heightCm}) {
  if (heightCm <= 0) {
    return 0;
  }
  final double heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}