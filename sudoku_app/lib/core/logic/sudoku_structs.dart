
enum Difficulty { easy, medium, hard }

class SudokuCell {
  int value; // 0-9, 0=empty
  final bool isFixed; // Given by puzzle, immutable
  Set<int> notes; // Candidates

  SudokuCell({
    required this.value,
    this.isFixed = false,
    Set<int>? notes,
  }) : notes = notes ?? {};

  // For deep copy if needed
  SudokuCell clone() {
    return SudokuCell(
      value: value,
      isFixed: isFixed,
      notes: Set<int>.from(notes),
    );
  }
}

class SudokuPuzzle {
  final String id;
  final Difficulty difficulty;
  final List<int> puzzleValues; // 81 length
  final List<int> solutionValues; // 81 length

  SudokuPuzzle({
    required this.id,
    required this.difficulty,
    required this.puzzleValues,
    required this.solutionValues,
  }) : assert(puzzleValues.length == 81 && solutionValues.length == 81);
}

class SudokuBoard {
  final SudokuPuzzle puzzle;
  late final List<SudokuCell> cells;

  SudokuBoard({
    required this.puzzle,
    required List<SudokuCell>? cells,
  }) {
    if (cells != null) {
      assert(cells.length == 81);
      this.cells = cells;
    } else {
      _initFromPuzzle();
    }
  }

  factory SudokuBoard.fromPuzzle(SudokuPuzzle puzzle) {
    return SudokuBoard(puzzle: puzzle, cells: null);
  }

  void _initFromPuzzle() {
    cells = List<SudokuCell>.generate(81, (index) {
      final val = puzzle.puzzleValues[index];
      return SudokuCell(
        value: val,
        isFixed: val != 0,
      );
    });
  }

  // Helpers
  // row: 0-8
  List<SudokuCell> rowOf(int rowIndex) {
    if (rowIndex < 0 || rowIndex > 8) throw RangeError.range(rowIndex, 0, 8);
    return cells.sublist(rowIndex * 9, (rowIndex + 1) * 9);
  }

  // col: 0-8
  List<SudokuCell> colOf(int colIndex) {
    if (colIndex < 0 || colIndex > 8) throw RangeError.range(colIndex, 0, 8);
    List<SudokuCell> res = [];
    for (int r = 0; r < 9; r++) {
      res.add(cells[r * 9 + colIndex]);
    }
    return res;
  }

  // box: 0-8
  // 0 1 2
  // 3 4 5
  // 6 7 8
  List<SudokuCell> boxOf(int boxIndex) {
    if (boxIndex < 0 || boxIndex > 8) throw RangeError.range(boxIndex, 0, 8);
    List<SudokuCell> res = [];
    int startRow = (boxIndex ~/ 3) * 3;
    int startCol = (boxIndex % 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        int index = (startRow + r) * 9 + (startCol + c);
        res.add(cells[index]);
      }
    }
    return res;
  }

  // Serialization
  Map<String, dynamic> toSnapshotJson() {
    return {
      'puzzleId': puzzle.id,
      'difficulty': puzzle.difficulty.name, // enum to string
      'values': cells.map((e) => e.value).toList(),
      'notes': cells.map((e) => e.notes.toList()).toList(),
    };
  }

  // This still requires the original Puzzle object to be available/loaded
  // or we need to pass a repository to look it up.
  // The requirement says: SudokuBoard fromSnapshotJson(...)
  // "需要保存：puzzle id、difficulty、当前 81 values、81 个 notes"
  // It implies we just reconstruct the state.
  // However, SudokuBoard HAS A SudokuPuzzle.
  // We can Reconstruction strategy:
  // Option A: Pass the full SudokuPuzzle object to fromSnapshotJson (if the app loaded it from repo)
  // Option B: create a dummy/partial puzzle if we only care about resuming state (but checking solution might fail if we don't have solutionValues).
  // Given "Puzzle Repository" exists, the typical flow is:
  // 1. Load snapshot JSON.
  // 2. Extract puzzleId.
  // 3. Fetch SudokuPuzzle from repo.
  // 4. Reconstruct Board.
  // I will implement a static method that takes the map and the puzzle.
  static SudokuBoard fromSnapshotJson(Map<String, dynamic> json, SudokuPuzzle puzzle) {
    if (json['puzzleId'] != puzzle.id) {
       throw ArgumentError("Puzzle ID mismatch: json[${json['puzzleId']}] != puzzle[${puzzle.id}]");
    }
    
    // Validate difficulty matches?
    // if (json['difficulty'] != puzzle.difficulty.name) ...

    List<int> values = List<int>.from(json['values']);
    List<List<int>> notesRaw = (json['notes'] as List).map((e) => List<int>.from(e)).toList();

    if (values.length != 81) throw ArgumentError("Snapshot values length must be 81");
    if (notesRaw.length != 81) throw ArgumentError("Snapshot notes length must be 81");

    List<SudokuCell> restoredCells = List.generate(81, (i) {
      // Re-determine isFixed from puzzle. It's safer than relying on snapshot if we trust the puzzle definition.
      bool isFixed = puzzle.puzzleValues[i] != 0;
      return SudokuCell(
        value: values[i],
        isFixed: isFixed,
        notes: Set<int>.from(notesRaw[i]),
      );
    });

    return SudokuBoard(puzzle: puzzle, cells: restoredCells);
  }
}
