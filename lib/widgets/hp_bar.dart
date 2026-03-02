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
    // SF2-authentic HP gradient: green → orange → red
    final hpColor = percent > 0.5
        ? const Color(0xFF39FF14)
        : percent > 0.25
            ? const Color(0xFFFF8C00)
            : const Color(0xFFFF1A00);

    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.vt323(
            textStyle: TextStyle(color: hpColor, fontSize: 16),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 130,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: hpColor.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: hpColor.withValues(alpha: 0.25),
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
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  width: 126 * percent.clamp(0.0, 1.0),
                  color: hpColor,
                ),
              ),
              // Segment dividers — 10 blocks like SF2
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
