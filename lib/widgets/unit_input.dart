import 'package:flutter/material.dart';

class UnitInput extends StatelessWidget {
  const UnitInput({super.key, required this.label, required this.controller, required this.suffix});

  final String label;
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}
