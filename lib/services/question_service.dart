import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/question.dart';

class QuestionService {
  final Map<QuizCategory, List<Question>> _questions = {};
  final Random _random = Random();

  Future<void> loadCategory(QuizCategory category) async {
    if (_questions.containsKey(category)) return;

    final fileName = _categoryToFileName(category);
    final jsonString = await rootBundle.loadString('assets/questions/$fileName');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _questions[category] = jsonList
        .map((json) => Question.fromJson(json as Map<String, dynamic>, category))
        .toList();
  }

  String _categoryToFileName(QuizCategory category) {
    switch (category) {
      case QuizCategory.popCulture:
        return 'pop_culture.json';
      case QuizCategory.worldHistory:
        return 'world_history.json';
      case QuizCategory.scienceSpace:
        return 'science_space.json';
      case QuizCategory.mathematics:
        return 'mathematics.json';
      case QuizCategory.geography:
        return 'geography.json';
      case QuizCategory.moviesTv:
        return 'movies_tv.json';
      case QuizCategory.music:
        return 'music.json';
      case QuizCategory.sports:
        return 'sports.json';
    }
  }

  List<Question> getQuestionsForMatch(
    QuizCategory category,
    Difficulty matchDifficulty, {
    int count = 30,
  }) {
    final categoryQuestions = _questions[category] ?? [];
    if (categoryQuestions.isEmpty) return [];

    List<Question> filtered;
    switch (matchDifficulty) {
      case Difficulty.rookie:
        filtered = categoryQuestions
            .where((q) => q.difficulty == Difficulty.rookie)
            .toList();
      case Difficulty.veteran:
        filtered = categoryQuestions
            .where((q) =>
                q.difficulty == Difficulty.rookie ||
                q.difficulty == Difficulty.veteran)
            .toList();
      case Difficulty.legend:
        filtered = List.from(categoryQuestions);
    }

    filtered.shuffle(_random);
    return filtered.take(count).toList();
  }
}
