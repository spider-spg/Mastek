import 'package:flutter/material.dart';

class QuickChips extends StatelessWidget {
  const QuickChips({super.key, required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          return ActionChip(
            label: Text(chips[index]),
            onPressed: () {},
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}
