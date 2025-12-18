import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/sudoku_structs.dart';
import '../logic/game_state.dart';
import '../logic/sudoku_repository.dart';

class PersistenceService {
  static const _keyGameSave = 'sudoku_game_save_v1';
  
  final SudokuPuzzleRepository _repository;

  PersistenceService(this._repository);

  Future<void> saveGame(SudokuGameState state) async {
    if (state.isCompleted) {
      clearSave();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    final snapshot = state.board.toSnapshotJson();
    final data = {
      'puzzleId': snapshot['puzzleId'],
      'difficulty': snapshot['difficulty'],
      'values': snapshot['values'],
      'notes': snapshot['notes'],
      'elapsedSeconds': state.elapsedSeconds,
      'conflictIndexes': state.conflictIndexes.toList(), // Optional, or recompute
      'isNoteMode': state.isNoteMode,
      // We don't save Undo Stack (too heavy/complex usually, user expects resume to current state)
    };

    await prefs.setString(_keyGameSave, jsonEncode(data));
  }

  Future<SudokuGameState?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyGameSave);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      final String puzzleId = json['puzzleId'];
      final int elapsedSeconds = json['elapsedSeconds'] ?? 0;
      final bool isNoteMode = json['isNoteMode'] ?? false;

      // Reconstruct
      final puzzle = _repository.getPuzzleById(puzzleId);
      final board = SudokuBoard.fromSnapshotJson(json, puzzle);
      
      // Re-validate to ensure conflict indexes are correct
      // We need to import validator but simpler to just let Notifier do it or do partial here?
      // Since SudokuGameState expects conflictIndexes, let's leave valid logic to Notifier? 
      // But GameState constructor requires it.
      // We can't easily compute conflicts here without Validator. 
      // Let's assume consumer calls Validator or we import it.
      // Better: Return a DTO or partial data? 
      // Or just import Validator? It's in core/logic.
      
      // Actually, we can return just the Board and metadata, and let Notifier build the state.
      // But method signature says `SudokuGameState?`.
      // I'll assume usage of empty conflicts and let Notifier recalculate upon load.
      
      return SudokuGameState(
        board: board,
        elapsedSeconds: elapsedSeconds,
        isNoteMode: isNoteMode,
        // Reset transient state
        selectedIndex: null,
        conflictIndexes: {}, // Will be recomputed by Notifier
        undoStack: [],
        redoStack: [],
        isCompleted: false, 
      );
    } catch (e) {
      // Corrupt save?
      clearSave();
      return null;
    }
  }

  Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGameSave);
  }

  Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyGameSave);
  }
}
