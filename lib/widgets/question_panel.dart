import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';

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
      final wrongIndices =
          List.generate(totalOptions, (i) => i).where((i) => i != correct).toList();
      wrongIndices.shuffle(_random);
      _visibleIndices = [correct, ...wrongIndices.take(optionCount - 1)];
      _visibleIndices.sort();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
      });
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
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) widget.onAnswer(originalIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['A', 'B', 'C', 'D'];
    final count = _visibleIndices.length;
    final crossAxisCount = count <= 2 ? 1 : 2;
    final aspectRatio = count <= 2 ? 5.0 : 3.0;

    final timerFraction = _timeRemaining / widget.timeLimit;
    final timerColor =
        _timeRemaining > 5 ? const Color(0xFF00FF00) : Colors.red;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF04020C),
        border: Border(
          top: BorderSide(color: Color(0xFFFF00FF), width: 3),
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
                style: GoogleFonts.pressStart2p(
                  textStyle: TextStyle(color: timerColor, fontSize: 7),
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
                            color: timerColor.withValues(alpha: 0.6),
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
                '${_timeRemaining}',
                style: GoogleFonts.pressStart2p(
                  textStyle: TextStyle(
                    color: timerColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Question text
          Text(
            widget.question.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Options grid
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: aspectRatio,
            children: _visibleIndices.map((origIdx) {
              final isSelected = _selectedIndex == origIdx;
              final isCorrect = origIdx == widget.question.correctIndex;
              final showResult = _answered;

              Color bgColor = Colors.black;
              Color borderColor = const Color(0xFF00FFFF).withValues(alpha: 0.5);
              Color textColor = Colors.white;

              if (showResult && isCorrect) {
                bgColor = const Color(0xFF00AA00).withValues(alpha: 0.3);
                borderColor = const Color(0xFF00FF00);
                textColor = const Color(0xFF00FF00);
              } else if (showResult && isSelected && !isCorrect) {
                bgColor = Colors.red.withValues(alpha: 0.25);
                borderColor = Colors.red;
                textColor = Colors.red;
              } else if (isSelected) {
                bgColor = const Color(0xFF00FFFF).withValues(alpha: 0.15);
                borderColor = const Color(0xFFFFFF00);
                textColor = const Color(0xFFFFFF00);
              }

              return GestureDetector(
                onTap: () => _selectAnswer(origIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: borderColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${labels[origIdx]}) ${widget.question.options[origIdx]}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
