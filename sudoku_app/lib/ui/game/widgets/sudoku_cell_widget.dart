import 'package:flutter/material.dart';
import '../../../../core/logic/sudoku_structs.dart';

class SudokuCellWidget extends StatefulWidget {
  final SudokuCell cell;
  final bool isSelected;
  final bool isRelated;
  final bool isSameValue;
  final bool isConflict;
  final VoidCallback onTap;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.isRelated,
    required this.isSameValue,
    required this.isConflict,
    required this.onTap,
  });

  @override
  State<SudokuCellWidget> createState() => _SudokuCellWidgetState();
}

class _SudokuCellWidgetState extends State<SudokuCellWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void didUpdateWidget(covariant SudokuCellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake if conflict appears
    if (!oldWidget.isConflict && widget.isConflict) {
      _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color
    Color bgColor = Colors.transparent;
    
    if (widget.isConflict) {
       bgColor = Theme.of(context).colorScheme.errorContainer;
    } else if (widget.isSelected) {
      bgColor = Theme.of(context).colorScheme.primaryContainer;
    } else if (widget.isSameValue) {
      bgColor = Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5);
    } else if (widget.isRelated) {
      bgColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
           return Transform.translate(
             offset: Offset(
               _shakeAnimation.value * (1.0 - _shakeController.value), // Decay shake 
               0
             ),
             child: child,
           );
        },
        child: Container(
          color: bgColor,
          child: Center(
            // Use AnimatedSwitcher for Entry Animation
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Value Key is crucial for AnimatedSwitcher to detect change
    if (widget.cell.value != 0) {
      Color textColor;
      if (widget.isConflict) {
        textColor = Theme.of(context).colorScheme.onErrorContainer;
      } else if (widget.cell.isFixed) {
        textColor = Theme.of(context).colorScheme.onSurface;
      } else {
        textColor = Theme.of(context).colorScheme.primary;
      }

      return Text(
        '${widget.cell.value}',
        key: ValueKey('v_${widget.cell.value}'),
        style: TextStyle(
          fontSize: 24,
          fontWeight: widget.cell.isFixed ? FontWeight.w800 : FontWeight.w400,
          color: textColor,
        ),
      );
    } else {
      if (widget.cell.notes.isEmpty) return const SizedBox(key: ValueKey('empty'));
      
      return LayoutBuilder(
        key: ValueKey('notes_${widget.cell.notes.length}'), 
        builder: (context, constraints) {
          double fontSize = constraints.maxWidth / 4;
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int r = 0; r < 3; r++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int c = 0; c < 3; c++)
                      _buildNoteDigit(r * 3 + c + 1, fontSize, context),
                  ],
                ),
            ],
          );
        },
      );
    }
  }

  Widget _buildNoteDigit(int digit, double fontSize, BuildContext context) {
    if (widget.cell.notes.contains(digit)) {
      return Text(
        '$digit',
        style: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.secondary,
          height: 1.0,
        ),
      );
    } else {
      return SizedBox(width: fontSize, height: fontSize);
    }
  }
}
