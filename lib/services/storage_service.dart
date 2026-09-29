import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _scoreKey = 'trivia_score';
  static const String _solvedFlagsKey = 'trivia_solved_flags';

  Future<int> loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scoreKey) ?? 0;
  }

  Future<void> saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoreKey, score);
  }

  Future<List<String>> loadSolvedFlags() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_solvedFlagsKey) ?? [];
  }

  Future<void> saveSolvedFlags(List<String> solvedFlags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_solvedFlagsKey, solvedFlags);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scoreKey);
    await prefs.remove(_solvedFlagsKey);
  }
}
