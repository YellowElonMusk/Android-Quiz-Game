import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';

class QuestionPanel extends StatefulWidget {
  final Question question;
  final ValueChanged<int> onAnswer;
  final Difficulty difficulty;
  final int timeLimit;

  const QuestionPanel({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.difficulty,
    this.timeLimit = 15,
  });

  @override
  State<QuestionPanel> createState() => _QuestionPanelState();
}

class _QuestionPanelState extends State<QuestionPanel> {
  int? _selectedIndex;
  late int _timeRemaining;
  Timer? _timer;
  bool _answered = false;

  /// The original indices of the options being displayed.
  /// For hard mode this is [0,1,2,3]. For easy mode it's 2 indices
  /// (always includes the correct answer).
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
  }

  void _buildVisibleIndices() {
    final optionCount = widget.difficulty.optionCount;
    final totalOptions = widget.question.options.length;
    final correct = widget.question.correctIndex;

    if (optionCount >= totalOptions) {
      // Hard mode: show all options
      _visibleIndices = List.generate(totalOptions, (i) => i);
    } else {
      // Easy mode: pick the correct answer + (optionCount-1) random wrong ones
      final wrongIndices =
          List.generate(totalOptions, (i) => i).where((i) => i != correct).toList();
      wrongIndices.shuffle(_random);
      _visibleIndices = [correct, ...wrongIndices.take(optionCount - 1)];
      _visibleIndices.sort(); // keep original order so positions stay consistent
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
          widget.onAnswer(-1); // timeout = wrong
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer bar
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _timeRemaining / widget.timeLimit,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timeRemaining > 5 ? Colors.greenAccent : Colors.redAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_timeRemaining}s',
                style: TextStyle(
                  color: _timeRemaining > 5 ? Colors.white70 : Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Question text
          Text(
            widget.question.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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

              Color bgColor = Colors.grey[800]!;
              if (showResult && isCorrect) {
                bgColor = Colors.green.withValues(alpha: 0.7);
              } else if (showResult && isSelected && !isCorrect) {
                bgColor = Colors.red.withValues(alpha: 0.7);
              } else if (isSelected) {
                bgColor = Colors.blueAccent.withValues(alpha: 0.5);
              }

              return GestureDetector(
                onTap: () => _selectAnswer(origIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${labels[origIdx]}) ${widget.question.options[origIdx]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
