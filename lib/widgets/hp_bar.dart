import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        ? const Color(0xFF00FF00)
        : percent > 0.25
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(
              color: hpColor,
              fontSize: 7,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 130,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: hpColor.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: hpColor.withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Filled HP
              Align(
                alignment:
                    alignRight ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  width: 126 * percent.clamp(0.0, 1.0),
                  color: hpColor,
                ),
              ),
              // Segment dividers
              Row(
                children: List.generate(
                  10,
                  (i) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: i < 9
                              ? const BorderSide(
                                  color: Colors.black, width: 2)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
