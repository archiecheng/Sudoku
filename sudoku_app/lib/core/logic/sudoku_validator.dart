import 'sudoku_structs.dart';

class SudokuValidator {
  
  // Returns true if placing [value] at [index] creates a conflict with existing numbers.
  // We exclude the cell at [index] itself from the check (in case we are validating a board that already has the value set temporarily, 
  // though the prompt says "put value... conflict with current board". Usually this implies checking against *other* cells).
  // If [value] is 0, return false (empty cell is valid).
  static bool isConflict(List<SudokuCell> cells, int index, int value) {
    if (value == 0) return false;

    int row = index ~/ 9;
    int col = index % 9;
    
    // Check Row
    for (int c = 0; c < 9; c++) {
      int idx = row * 9 + c;
      if (idx == index) continue; // Skip self
      if (cells[idx].value == value) return true;
    }

    // Check Col
    for (int r = 0; r < 9; r++) {
      int idx = r * 9 + col;
      if (idx == index) continue; // Skip self
      if (cells[idx].value == value) return true;
    }

    // Check Box
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        int idx = (startRow + r) * 9 + (startCol + c);
        if (idx == index) continue; // Skip self
        if (cells[idx].value == value) return true;
      }
    }

    return false;
  }

  // Returns a Set of all indices that are participating in a conflict.
  static Set<int> computeConflictIndexes(List<SudokuCell> cells) {
    Set<int> conflicts = {};

    // Helper to check a group of indices
    void checkGroup(List<int> indices) {
      // Map value -> List of indices having that value
      Map<int, List<int>> valueMap = {};
      for (int idx in indices) {
        int v = cells[idx].value;
        if (v != 0) {
          if (!valueMap.containsKey(v)) valueMap[v] = [];
          valueMap[v]!.add(idx);
        }
      }
      // If any value appears > 1 times, all those indices are conflicts
      for (var entry in valueMap.entries) {
        if (entry.value.length > 1) {
          conflicts.addAll(entry.value);
        }
      }
    }

    // Rows
    for (int r = 0; r < 9; r++) {
      List<int> indices = List.generate(9, (c) => r * 9 + c);
      checkGroup(indices);
    }

    // Cols
    for (int c = 0; c < 9; c++) {
      List<int> indices = List.generate(9, (r) => r * 9 + c);
      checkGroup(indices);
    }

    // Boxes
    for (int b = 0; b < 9; b++) {
      List<int> indices = [];
      int startRow = (b ~/ 3) * 3;
      int startCol = (b % 3) * 3;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          indices.add((startRow + r) * 9 + (startCol + c));
        }
      }
      checkGroup(indices);
    }

    return conflicts;
  }

  static bool isSolved(SudokuBoard board) {
    // 1. All cells filled
    for (var cell in board.cells) {
      if (cell.value == 0) return false;
    }

    // 2. No conflicts
    if (computeConflictIndexes(board.cells).isNotEmpty) return false;

    // Optional: Check against solution if available?
    // Requirement says: "value != 0 and no conflict".
    // It implies self-consistency check. 
    // Usually Sudoku apps also check against the known unique solution to be safe, 
    // but strict "isSolved" by rules of Sudoku relies on constraints.
    // However, sometimes a filled board can adhere to rules but not be the *intended* solution? 
    // Actually, if a Sudoku has a unique solution, rule-adherence implies solution-match.
    // But if we have `solutionValues`, we can also do a quick check:
    /*
    for (int i = 0; i < 81; i++) {
      if (board.cells[i].value != board.puzzle.solutionValues[i]) return false;
    }
    */
    // The requirement says: "isSolved(SudokuBoard board)：所有格子 value !=0 且无冲突。"
    // So we assume constraint satisfaction is enough.
    
    return true;
  }
}
