import 'dart:convert';
import 'dart:math';

import 'sudoku_structs.dart';

class SudokuPuzzleRepository {
  List<SudokuPuzzle> _allPuzzles = [];

  // In a real app, this might be async and load from assets/file
  void loadPuzzles() {
    // Example JSON structure provided in code
    const String jsonString = '''
    [
      {
        "id": "e_001",
        "difficulty": "easy",
        "puzzle": "000000010400000000020000000000050407008000300001090000300400200050100000000806000",
        "solution": "693784512487512963125963874932658427568247391741395684376421259259178643814836952"
      },
      {
        "id": "m_001",
        "difficulty": "medium",
        "puzzle": "000000010400000000020000000000050407008000300001090000300400200050100000000806000",
        "solution": "693784512487512963125963874932658427568247391741395684376421259259178643814836952"
      },
      {
        "id": "h_001",
        "difficulty": "hard",
        "puzzle": "000000010400000000020000000000050407008000300001090000300400200050100000000806000",
        "solution": "693784512487512963125963874932658427568247391741395684376421259259178643814836952"
      }
    ]
    ''';

    _allPuzzles = _parsePuzzlesFromJson(jsonString);
  }

  // Exposed for testing if needed
  List<SudokuPuzzle> parsePuzzlesRaw(String jsonString) {
    return _parsePuzzlesFromJson(jsonString);
  }

  List<SudokuPuzzle> _parsePuzzlesFromJson(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((item) {
      final String id = item['id'];
      final String diffStr = item['difficulty'];
      final String puzzleStr = item['puzzle'];
      final String solStr = item['solution'];

      Difficulty diff;
      switch (diffStr) {
        case 'easy': diff = Difficulty.easy; break;
        case 'medium': diff = Difficulty.medium; break;
        case 'hard': diff = Difficulty.hard; break;
        default: diff = Difficulty.easy;
      }

      return SudokuPuzzle(
        id: id,
        difficulty: diff,
        puzzleValues: _stringToValues(puzzleStr),
        solutionValues: _stringToValues(solStr),
      );
    }).toList();
  }

  List<int> _stringToValues(String s) {
    return s.split('').map((ch) {
      int? v = int.tryParse(ch);
      return v ?? 0;
    }).toList();
  }

  SudokuPuzzle getRandom(Difficulty difficulty, {int? seed}) {
    // If not loaded yet, load (naive lazy load)
    if (_allPuzzles.isEmpty) loadPuzzles();

    final candidates = _allPuzzles.where((p) => p.difficulty == difficulty).toList();
    if (candidates.isEmpty) {
      // Fallback or throw? Requirements imply there's a repository.
      // For now, return a placeholder or throw.
      throw StateError("No puzzles found for difficulty $difficulty");
    }

    final random = Random(seed);
    return candidates[random.nextInt(candidates.length)];
  }
}
