import 'package:flutter/material.dart';

class HpBar extends StatelessWidget {
  final double percent;
  final Color color;
  final String label;
  final bool alignRight;

  const HpBar({
    super.key,
    required this.percent,
    required this.color,
    required this.label,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final hpColor = percent > 0.5
        ? color
        : percent > 0.25
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 140,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Align(
              alignment:
                  alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: 140 * percent.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [hpColor.withValues(alpha: 0.8), hpColor],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(percent * 500).round()} / 500',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
