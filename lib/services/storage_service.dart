import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _runsKey = 'free_runs_used';
  static const String _isPaidKey = 'is_paid';
  static const String _highStreakKey = 'high_streak';
  static const String _totalWinsKey = 'total_wins';
  static const int maxFreeRuns = 3;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get freeRunsUsed => _prefs.getInt(_runsKey) ?? 0;
  bool get isPaid => _prefs.getBool(_isPaidKey) ?? false;
  int get highStreak => _prefs.getInt(_highStreakKey) ?? 0;
  int get totalWins => _prefs.getInt(_totalWinsKey) ?? 0;

  bool get canPlay => isPaid || freeRunsUsed < maxFreeRuns;
  int get freeRunsRemaining => maxFreeRuns - freeRunsUsed;

  Future<void> useRun() async {
    if (!isPaid) {
      await _prefs.setInt(_runsKey, freeRunsUsed + 1);
    }
  }

  Future<void> setPaid(bool paid) async {
    await _prefs.setBool(_isPaidKey, paid);
  }

  Future<void> updateHighStreak(int streak) async {
    if (streak > highStreak) {
      await _prefs.setInt(_highStreakKey, streak);
    }
  }

  Future<void> addWin() async {
    await _prefs.setInt(_totalWinsKey, totalWins + 1);
  }
}
