import 'package:flutter/foundation.dart';
import '../logic/sudoku_structs.dart';

class StatsService {
  // Simple in-memory storage. 
  // Key: Difficulty.name
  // Value: Best time in seconds (null if none)
  static final Map<String, int> _bestTimes = {};

  static Future<void> saveBestTime(Difficulty difficulty, int seconds) async {
    final key = difficulty.name;
    final current = _bestTimes[key];

    if (current == null || seconds < current) {
      _bestTimes[key] = seconds;
      debugPrint("New Best Time for $key: $seconds s");
    }
  }

  static int? getBestTime(Difficulty difficulty) {
    return _bestTimes[difficulty.name];
  }
}
