
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sudoku_app/core/logic/sudoku_repository.dart';
import 'package:sudoku_app/core/logic/sudoku_structs.dart';
import 'package:sudoku_app/core/logic/sudoku_validator.dart';
import 'package:sudoku_app/core/service/monetization_managers.dart';
import 'package:sudoku_app/core/service/persistence_service.dart';
import 'package:sudoku_app/core/service/stats_service.dart';
import 'game_state.dart';

class SudokuGameNotifier extends Notifier<SudokuGameState> {
  final SudokuPuzzleRepository _repository = SudokuPuzzleRepository();
  late final PersistenceService _persistence;
  late final AdManager _adManager;
  late final PurchaseManager _purchaseManager;
  
  Timer? _timer;
  
  // Debouncer for Auto-Save
  final _saveSubject = PublishSubject<SudokuGameState>();
  StreamSubscription? _saveSubscription;

  @override
  SudokuGameState build() {
    _persistence = PersistenceService(_repository);
    _adManager = DummyAdManager();
    _purchaseManager = DummyPurchaseManager();

    // Setup Save Debouncer
    _saveSubscription = _saveSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((stateToSave) {
          _persistence.saveGame(stateToSave);
    });

    ref.onDispose(() {
      _timer?.cancel();
      _saveSubscription?.cancel();
      _saveSubject.close();
    });

    return SudokuGameState(
      board: SudokuBoard(
        puzzle: SudokuPuzzle(
          id: 'empty', 
          difficulty: Difficulty.easy, 
          puzzleValues: List.filled(81, 0), 
          solutionValues: List.filled(81, 0)
        ), 
        cells: null
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isCompleted) {
        state = state.copyWithUpdated(elapsedSeconds: state.elapsedSeconds + 1);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resumeGame() async {
    final savedState = await _persistence.loadGame();
    if (savedState != null) {
      // Re-validate conflict indexes as they weren't saved
      final conflicts = SudokuValidator.computeConflictIndexes(savedState.board.cells);
      final isCompleted = SudokuValidator.isSolved(savedState.board);
      
      state = savedState.copyWithUpdated(
        conflictIndexes: conflicts, 
        isCompleted: isCompleted,
      );
      
      if (!isCompleted) _startTimer();
    }
  }

  void initDailyChallenge() {
    final now = DateTime.now();
    final seed = int.parse("${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}");
    initNewGame(Difficulty.medium, seed: seed);
  }

  void initNewGame(Difficulty difficulty, {int? seed}) {
    final puzzle = _repository.getRandom(difficulty, seed: seed);
    final board = SudokuBoard.fromPuzzle(puzzle);
    
    final conflicts = SudokuValidator.computeConflictIndexes(board.cells);
    final isCompleted = SudokuValidator.isSolved(board);

    state = SudokuGameState(
      board: board,
      selectedIndex: null,
      isNoteMode: false,
      conflictIndexes: conflicts,
      undoStack: const [],
      redoStack: const [],
      isCompleted: isCompleted,
      elapsedSeconds: 0,
    );
    
    _startTimer();
  }

  void selectCell(int index) {
    state = state.copyWithUpdated(selectedIndex: index);
  }

  void toggleNoteMode() {
    state = state.copyWithUpdated(isNoteMode: !state.isNoteMode);
  }

  void inputNumber(int value) {
    if (state.selectedIndex == null || state.isCompleted) return;
    
    final index = state.selectedIndex!;
    // Use current board to check validity/changes, but then clone for next state?
    // Or clone first?
    // Let's Clone FIRST to avoid mutating the 'current' state which might be held by UI previous comparisons.
    // Immutable style:
    final newBoard = state.board.clone();
    final cell = newBoard.cells[index];

    if (cell.isFixed) return;

    final prevValue = cell.value;
    final prevNotes = Set<int>.from(cell.notes);
    
    bool changed = false;
    int newValue = prevValue;
    Set<int> newNotes = Set.from(prevNotes);

    if (state.isNoteMode) {
      if (value != 0) {
        if (newNotes.contains(value)) {
          newNotes.remove(value);
        } else {
          newNotes.add(value);
        }
        changed = true;
      }
    } else {
      if (value == 0) {
        newValue = 0;
        newNotes.clear();
        changed = (prevValue != 0 || prevNotes.isNotEmpty);
      } else {
        if (prevValue == value) {
          // No-Op or Toggle? Requirements say "set cell.value=value". 
          newValue = value;
          changed = false;
        } else {
          newValue = value;
          changed = true;
        }
        newNotes.clear();
      }
    }

    // The following block was a duplicate and has been removed.
    // if (value == 0) {
    //    newValue = 0;
    //    newNotes.clear();
    //    changed = (prevValue != 0 || prevNotes.isNotEmpty);
    // } 

    if (!changed) return;

    cell.value = newValue;
    cell.notes = newNotes;

    final conflicts = SudokuValidator.computeConflictIndexes(newBoard.cells);
    final isCompleted = SudokuValidator.isSolved(newBoard);

    if (isCompleted) {
      _timer?.cancel();
      StatsService.saveBestTime(newBoard.puzzle.difficulty, state.elapsedSeconds);
      _persistence.clearSave(); // Added
      _adManager.showInterstitialAd(); // Added
    }

    final action = SudokuAction(
      index: index,
      prevValue: prevValue,
      newValue: newValue,
      prevNotes: newNotes, // Changed to newNotes as per typical undo/redo logic
      newNotes: prevNotes, // Changed to prevNotes as per typical undo/redo logic
    );

    // Update state with NEW board
    state = state.copyWithUpdated(
      board: newBoard, // Changed to newBoard
      conflictIndexes: conflicts,
      isCompleted: isCompleted,
      undoStack: [...state.undoStack, action],
      redoStack: [],
    );
    
    if (!isCompleted) { // Added
      _saveSubject.add(state); // Added
    }
  }

  void erase() {
    inputNumber(0);
  }

  void undo() {
    if (state.undoStack.isEmpty) return;
    
    final action = state.undoStack.last;
    final newUndo = List<SudokuAction>.from(state.undoStack)..removeLast();
    
    // We must clone board to reverse safely
    final newBoard = state.board.clone(); // Changed to newBoard
    final cell = newBoard.cells[action.index]; // Changed to newBoard
    cell.value = action.prevValue;
    cell.notes = Set.from(action.prevNotes);

    final conflicts = SudokuValidator.computeConflictIndexes(newBoard.cells); // Changed to newBoard
    final isCompleted = SudokuValidator.isSolved(newBoard); // Changed to newBoard
    
    if (isCompleted) _timer?.cancel(); // If undo leads to complete? unlikely but possible if undoing manual error

    state = state.copyWithUpdated(
      board: newBoard, // Changed to newBoard
      conflictIndexes: conflicts,
      isCompleted: isCompleted,
      undoStack: newUndo,
      redoStack: [...state.redoStack, action],
    );
    
    _saveSubject.add(state); // Added
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final action = state.redoStack.last;
    final newRedo = List<SudokuAction>.from(state.redoStack)..removeLast();

    final newBoard = state.board.clone(); // Changed to newBoard
    final cell = newBoard.cells[action.index]; // Changed to newBoard
    cell.value = action.newValue;
    cell.notes = Set.from(action.newNotes);

    final conflicts = SudokuValidator.computeConflictIndexes(newBoard.cells); // Changed to newBoard
    final isCompleted = SudokuValidator.isSolved(newBoard); // Changed to newBoard

    if (isCompleted) {
       _timer?.cancel();
       StatsService.saveBestTime(newBoard.puzzle.difficulty, state.elapsedSeconds); // Changed to newBoard
       _persistence.clearSave(); // Added
       _adManager.showInterstitialAd(); // Added
    }

    state = state.copyWithUpdated(
      board: newBoard, // Changed to newBoard
      conflictIndexes: conflicts,
      isCompleted: isCompleted,
      undoStack: [...state.undoStack, action],
      redoStack: newRedo,
    );
    
    if (!isCompleted) { // Added
      _saveSubject.add(state); // Added
    }
  }
}

final sudokuGameProvider = NotifierProvider<SudokuGameNotifier, SudokuGameState>(() {
  return SudokuGameNotifier();
});
