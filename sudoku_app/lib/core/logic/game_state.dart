import 'package:equatable/equatable.dart';
import 'sudoku_structs.dart';

class SudokuAction extends Equatable {
  final int index;
  final int prevValue;
  final int newValue;
  final Set<int> prevNotes;
  final Set<int> newNotes;

  const SudokuAction({
    required this.index,
    required this.prevValue,
    required this.newValue,
    required this.prevNotes,
    required this.newNotes,
  });

  @override
  List<Object?> get props => [index, prevValue, newValue, prevNotes, newNotes];
}

class SudokuGameState extends Equatable {
  final SudokuBoard board; // Mutable internally but treated as part of state snapshot
  final int? selectedIndex;
  final bool isNoteMode;
  final Set<int> conflictIndexes;
  final List<SudokuAction> undoStack;
  final List<SudokuAction> redoStack;
  final bool isCompleted;
  final int elapsedSeconds;

  const SudokuGameState({
    required this.board,
    this.selectedIndex,
    this.isNoteMode = false,
    this.conflictIndexes = const {},
    this.undoStack = const [],
    this.redoStack = const [],
    this.isCompleted = false,
    this.elapsedSeconds = 0,
  });

  SudokuGameState copyWith({
    SudokuBoard? board,
    int? selectedIndex,
    bool? isNoteMode,
    Set<int>? conflictIndexes,
    List<SudokuAction>? undoStack,
    List<SudokuAction>? redoStack,
    bool? isCompleted,
    int? elapsedSeconds,
  }) {
    return SudokuGameState(
      board: board ?? this.board, // Warning: SudokuBoard is mutable, be careful to deep copy/recreate if needed for strict immutability
      selectedIndex: selectedIndex, 
      isNoteMode: isNoteMode ?? this.isNoteMode,
      conflictIndexes: conflictIndexes ?? this.conflictIndexes,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    ) // We need to handle selectedIndex carefully below
    .copyWithSelectedIndex(selectedIndex);
  }

  // Separate method/logic for nullable field
  SudokuGameState copyWithSelectedIndex(int? newIndex) {
    return SudokuGameState(
      board: board,
      selectedIndex: newIndex ?? selectedIndex,
      isNoteMode: isNoteMode,
      conflictIndexes: conflictIndexes,
      undoStack: undoStack,
      redoStack: redoStack,
      isCompleted: isCompleted,
      elapsedSeconds: elapsedSeconds,
    );
  }

  // Better CopyWith that supports nullable updates using a Sentinel or wrapper
  SudokuGameState copyWithUpdated({
    SudokuBoard? board,
    int? selectedIndex,
    bool? clearSelection, // Helper flag
    bool? isNoteMode,
    Set<int>? conflictIndexes,
    List<SudokuAction>? undoStack,
    List<SudokuAction>? redoStack,
    bool? isCompleted,
    int? elapsedSeconds,
  }) {
    return SudokuGameState(
      board: board ?? this.board,
      selectedIndex: (clearSelection == true) ? null : (selectedIndex ?? this.selectedIndex),
      isNoteMode: isNoteMode ?? this.isNoteMode,
      conflictIndexes: conflictIndexes ?? this.conflictIndexes,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  @override
  List<Object?> get props => [
    board, 
    selectedIndex,
    isNoteMode,
    conflictIndexes,
    undoStack,
    redoStack,
    isCompleted,
    elapsedSeconds,
  ];
}
