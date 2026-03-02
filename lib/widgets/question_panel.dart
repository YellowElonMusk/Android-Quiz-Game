import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';

// Question panel deliberately uses a cooler, more clinical background
// to contrast with the warm arcade arena above it.
// The exam-bubble answer buttons are the product signature:
// academic dread + arcade urgency, physically expressed.

class QuestionPanel extends StatefulWidget {
  final Question question;
  final ValueChanged<int> onAnswer;
  final Difficulty difficulty;
  final int timeLimit;
  final bool paused;

  const QuestionPanel({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.difficulty,
    this.timeLimit = 15,
    this.paused = false,
  });

  @override
  State<QuestionPanel> createState() => _QuestionPanelState();
}

class _QuestionPanelState extends State<QuestionPanel> {
  int? _selectedIndex;
  int? _pressedIndex; // tracks physical press for scale animation
  late int _timeRemaining;
  Timer? _timer;
  bool _answered = false;
  late List<int> _visibleIndices;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.timeLimit;
    _buildVisibleIndices();
    _startTimer();
  }

  @override
  void didUpdateWidget(QuestionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _timer?.cancel();
      _selectedIndex = null;
      _pressedIndex = null;
      _answered = false;
      _timeRemaining = widget.timeLimit;
      _buildVisibleIndices();
      _startTimer();
    }
    if (widget.paused && !oldWidget.paused) {
      _timer?.cancel();
    } else if (!widget.paused && oldWidget.paused && !_answered) {
      _startTimer();
    }
  }

  void _buildVisibleIndices() {
    final optionCount = widget.difficulty.optionCount;
    final totalOptions = widget.question.options.length;
    final correct = widget.question.correctIndex;
    if (optionCount >= totalOptions) {
      _visibleIndices = List.generate(totalOptions, (i) => i);
    } else {
      final wrong = List.generate(totalOptions, (i) => i)
          .where((i) => i != correct)
          .toList()
        ..shuffle(_random);
      _visibleIndices = [correct, ...wrong.take(optionCount - 1)]..sort();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _timeRemaining--);
      if (_timeRemaining <= 0) {
        timer.cancel();
        if (!_answered) {
          _answered = true;
          widget.onAnswer(-1);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectAnswer(int originalIndex) {
    if (_answered) return;
    _answered = true;
    _timer?.cancel();
    setState(() {
      _selectedIndex = originalIndex;
      _pressedIndex = null;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) widget.onAnswer(originalIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['A', 'B', 'C', 'D'];
    final count = _visibleIndices.length;
    final crossAxisCount = count <= 2 ? 1 : 2;
    final aspectRatio = count <= 2 ? 4.2 : 2.8;

    final timerFraction = _timeRemaining / widget.timeLimit;
    final urgent = _timeRemaining <= 5;
    final timerColor = urgent ? const Color(0xFFFF1A00) : const Color(0xFF39FF14);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF080C18), // deliberately cooler than warm arena above
        border: Border(
          top: BorderSide(color: Color(0xFFFF4500), width: 3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer row
          Row(
            children: [
              Text(
                'TIME',
                style: GoogleFonts.vt323(
                  textStyle: TextStyle(color: timerColor, fontSize: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(
                            color: timerColor.withValues(alpha: 0.5),
                            width: 1),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear,
                          width: constraints.maxWidth *
                              timerFraction.clamp(0.0, 1.0),
                          color: timerColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_timeRemaining',
                style: GoogleFonts.vt323(
                  textStyle: TextStyle(
                    color: timerColor,
                    fontSize: 28,
                    shadows: urgent
                        ? [
                            BoxShadow(
                              color: timerColor.withValues(alpha: 0.6),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Question text — readable, slightly warm
          Text(
            widget.question.text,
            style: const TextStyle(
              color: Color(0xFFF0E8D0), // warm off-white, like exam paper
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Answer buttons — exam bubble style
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: aspectRatio,
            children: _visibleIndices.map((origIdx) {
              return _buildAnswerButton(origIdx, labels);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int origIdx, List<String> labels) {
    final isSelected = _selectedIndex == origIdx;
    final isCorrect = origIdx == widget.question.correctIndex;
    final showResult = _answered;
    final isPressed = _pressedIndex == origIdx;

    // Color logic: result > selected > default
    Color bubbleFill = Colors.transparent;
    Color borderColor = const Color(0xFFFFB800).withValues(alpha: 0.5);
    Color textColor = const Color(0xFFD0C8A0); // parchment
    Color bubbleBorderColor = const Color(0xFFFFB800).withValues(alpha: 0.5);

    if (showResult && isCorrect) {
      bubbleFill = const Color(0xFF39FF14).withValues(alpha: 0.25);
      borderColor = const Color(0xFF39FF14);
      bubbleBorderColor = const Color(0xFF39FF14);
      textColor = const Color(0xFF39FF14);
    } else if (showResult && isSelected && !isCorrect) {
      bubbleFill = const Color(0xFFFF1A00).withValues(alpha: 0.25);
      borderColor = const Color(0xFFFF1A00);
      bubbleBorderColor = const Color(0xFFFF1A00);
      textColor = const Color(0xFFFF4040);
    } else if (isSelected) {
      bubbleFill = const Color(0xFFFFB800).withValues(alpha: 0.30);
      borderColor = const Color(0xFFFFB800);
      bubbleBorderColor = const Color(0xFFFFB800);
      textColor = const Color(0xFFFFB800);
    }

    return GestureDetector(
      onTapDown: (_) {
        if (!_answered) setState(() => _pressedIndex = origIdx);
      },
      onTapUp: (_) {
        setState(() => _pressedIndex = null);
        _selectAnswer(origIdx);
      },
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedScale(
        scale: isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? borderColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Exam bubble — the signature element
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(left: 10, right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: bubbleBorderColor, width: 2),
                  color: bubbleFill,
                ),
                child: Center(
                  child: Text(
                    labels[origIdx],
                    style: GoogleFonts.blackOpsOne(
                      textStyle: TextStyle(
                        color: isSelected
                            ? bubbleBorderColor
                            : const Color(0xFFFFB800).withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
              // Answer text
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Text(
                    widget.question.options[origIdx],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
