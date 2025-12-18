import 'package:flutter/material.dart';
import '../../../../core/logic/sudoku_structs.dart';
import 'sudoku_cell_widget.dart';

class SudokuBoardWidget extends StatelessWidget {
  final SudokuBoard board;
  final int selectedIndex; // -1 if none
  final Set<int> conflictIndexes;
  final Function(int) onCellTap;

  const SudokuBoardWidget({
    super.key,
    required this.board,
    required this.selectedIndex,
    required this.conflictIndexes,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4), 
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 81,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemBuilder: (context, index) {
            return _buildCell(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int index) {
    final cell = board.cells[index];
    
    // Calculate borders
    int row = index ~/ 9;
    int col = index % 9;
    
    bool rightBorder = (col == 2 || col == 5);
    bool bottomBorder = (row == 2 || row == 5);
    
    // Highlighting Logic
    bool isSelected = (index == selectedIndex);
    bool isConflict = conflictIndexes.contains(index);
    
    bool isRelated = false;
    bool isSameValue = false;

    if (selectedIndex != -1) {
      int selRow = selectedIndex ~/ 9;
      int selCol = selectedIndex % 9;
      
      // Related: Same Row, Col, or Box
      bool sameRow = (row == selRow);
      bool sameCol = (col == selCol);
      bool sameBox = (row ~/ 3 == selRow ~/ 3) && (col ~/ 3 == selCol ~/ 3);
      
      if (!isSelected && (sameRow || sameCol || sameBox)) {
        isRelated = true;
      }
      
      // Same Value
      int selValue = board.cells[selectedIndex].value;
      if (selValue != 0 && cell.value == selValue) {
        isSameValue = true;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: rightBorder ? Colors.black87 : Colors.black12,
            width: rightBorder ? 2.0 : 0.5,
          ),
          bottom: BorderSide(
            color: bottomBorder ? Colors.black87 : Colors.black12,
            width: bottomBorder ? 2.0 : 0.5,
          ),
        ),
      ),
      child: SudokuCellWidget(
        cell: cell,
        isSelected: isSelected,
        isRelated: isRelated,
        isSameValue: isSameValue,
        isConflict: isConflict,
        onTap: () => onCellTap(index),
      ),
    );
  }
}
