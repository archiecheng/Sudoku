
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/core/logic/sudoku_structs.dart';
import 'package:sudoku_app/core/logic/sudoku_validator.dart';
import 'package:sudoku_app/core/logic/sudoku_repository.dart';

void main() {
  group('Sudoku Structs Tests', () {
    test('SudokuBoard initialization from Puzzle', () {
      final puzzle = SudokuPuzzle(
        id: 'test_1',
        difficulty: Difficulty.easy,
        puzzleValues: List.filled(81, 0)..[0] = 5,
        solutionValues: List.filled(81, 1),
      );

      final board = SudokuBoard.fromPuzzle(puzzle);
      expect(board.cells.length, 81);
      
      // Cell 0 should be fixed and value 5
      expect(board.cells[0].value, 5);
      expect(board.cells[0].isFixed, true);

      // Cell 1 should be empty and not fixed
      expect(board.cells[1].value, 0);
      expect(board.cells[1].isFixed, false);
    });

    test('Helpers: rowOf, colOf, boxOf', () {
      final puzzle = SudokuPuzzle(
        id: 'test_0',
        difficulty: Difficulty.easy,
        puzzleValues: List.generate(81, (i) => i), // 0..80
        solutionValues: List.filled(81, 0),
      );
      final board = SudokuBoard.fromPuzzle(puzzle);

      // Row 0: 0..8
      final row0 = board.rowOf(0);
      expect(row0.map((c) => c.value).toList(), [0,1,2,3,4,5,6,7,8]);

      // Col 0: 0, 9, 18 ... 72
      final col0 = board.colOf(0);
      expect(col0[1].value, 9);
      expect(col0[8].value, 72);

      // Box 0: 0,1,2, 9,10,11, 18,19,20
      final box0 = board.boxOf(0);
      expect(box0.map((c) => c.value).toList(), [0,1,2, 9,10,11, 18,19,20]);
    });
  });

  group('Sudoku Validator Tests', () {
    late SudokuBoard board;

    setUp(() {
       // Create an empty board for easier testing
       final puzzle = SudokuPuzzle(
         id: 'v_test', 
         difficulty: Difficulty.easy, 
         puzzleValues: List.filled(81, 0), 
         solutionValues: List.filled(81, 0)
       );
       board = SudokuBoard.fromPuzzle(puzzle);
    });

    test('isConflict detection', () {
      // Setup: place 5 at (0,0) [Index 0]
      board.cells[0].value = 5;

      // Conflict in Row: (0,1) try 5
      expect(SudokuValidator.isConflict(board.cells, 1, 5), true);
      // No conflict in Row: (0,1) try 4
      expect(SudokuValidator.isConflict(board.cells, 1, 4), false);

      // Conflict in Col: (1,0) [Index 9] try 5
      expect(SudokuValidator.isConflict(board.cells, 9, 5), true);

      // Conflict in Box: (1,1) [Index 10] try 5
      expect(SudokuValidator.isConflict(board.cells, 10, 5), true);
      
      // No conflict far away: (8,8) [Index 80] try 5
      expect(SudokuValidator.isConflict(board.cells, 80, 5), false);
    });

    test('computeConflictIndexes', () {
      // Row conflict: Row 0 has two 5s at index 0 and 1
      board.cells[0].value = 5;
      board.cells[1].value = 5;
      
      // Col conflict: Col 2 has two 9s at index 2 and 11
      board.cells[2].value = 9;
      board.cells[11].value = 9;

      var conflicts = SudokuValidator.computeConflictIndexes(board.cells);
      expect(conflicts, containsAll([0, 1, 2, 11]));
      expect(conflicts.length, 4);
    });

    test('isSolved', () {
      // Construct a trivial solved board (all 1s is invalid, but let's make a valid small one? 
      // Actually standard sudoku logic prevents easy valid construct without complexity.
      // Let's rely on conflicts logic.
      // Board with 0s is not solved.
      expect(SudokuValidator.isSolved(board), false);

      // Fill with 1s -> Conflict -> Not solved
      for(var c in board.cells) c.value = 1;
      expect(SudokuValidator.isSolved(board), false);

      // We need a valid solution to pass isSolved.
      // Let's use Repository's example solution if possible, or mock one.
      // Or just trusted data.
    });
  });

  group('Serialization Tests', () {
    test('toSnapshotJson and fromSnapshotJson', () {
      final puzzle = SudokuPuzzle(
        id: 's_test',
        difficulty: Difficulty.medium,
        puzzleValues: List.filled(81, 0),
        solutionValues: List.filled(81, 0),
      );
      final board = SudokuBoard.fromPuzzle(puzzle);
      
      // Modify state
      board.cells[0].value = 9;
      board.cells[0].notes = {1, 2};
      board.cells[5].value = 3; 

      final json = board.toSnapshotJson();
      
      expect(json['puzzleId'], 's_test');
      expect(json['difficulty'], 'medium');
      expect((json['values'] as List)[0], 9);
      
      // Restore
      final restoredBoard = SudokuBoard.fromSnapshotJson(json, puzzle);
      expect(restoredBoard.cells[0].value, 9);
      expect(restoredBoard.cells[0].notes, {1, 2});
      expect(restoredBoard.cells[5].value, 3);
      expect(restoredBoard.cells[80].value, 0);
    });
  });

  group('Repository Tests', () {
    test('Parse and getRandom', () {
       final repo = SudokuPuzzleRepository();
       // This uses the hardcoded JSON in the class
       final puzzle = repo.getRandom(Difficulty.easy, seed: 123);
       
       expect(puzzle.difficulty, Difficulty.easy);
       expect(puzzle.puzzleValues.length, 81);
       // Check a known value from the example json "easy" string
       // "000000010..." -> Index 7 is '1' (which is index 7 value 1).
       // 0-based index 7.
       expect(puzzle.puzzleValues[7], 1);
    });
  });
}
