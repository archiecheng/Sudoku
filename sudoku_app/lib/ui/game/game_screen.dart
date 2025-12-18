
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/logic/sudoku_structs.dart';
import '../../../../core/logic/game_notifier.dart';
import '../../../../core/service/stats_service.dart';
import 'widgets/sudoku_board_widget.dart';
import 'widgets/number_pad_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Difficulty difficulty;
  final bool isResume;
  final bool isDaily;

  const GameScreen({
    super.key, 
    required this.difficulty,
    this.isResume = false,
    this.isDaily = false,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ConfettiController _confettiController;
  bool _hasShownCompletionDialog = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    Future.microtask(() {
      if (widget.isResume) {
        ref.read(sudokuGameProvider.notifier).resumeGame();
      } else if (widget.isDaily) {
        ref.read(sudokuGameProvider.notifier).initDailyChallenge();
      } else {
        ref.read(sudokuGameProvider.notifier).initNewGame(widget.difficulty);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showCompletionDialog(int seconds) {
    if (_hasShownCompletionDialog) return;
    _hasShownCompletionDialog = true;

    _confettiController.play();
    HapticFeedback.heavyImpact();
    
    final bestTime = StatsService.getBestTime(widget.difficulty);
    final isNewBest = bestTime != null && seconds <= bestTime;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text("Puzzle Solved!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Difficulty: ${widget.difficulty.name.toUpperCase()}"),
             const SizedBox(height: 8),
             Text("Time: ${_formatTime(seconds)}"),
             if (isNewBest) 
               const Text("New Best Time! 🏆", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
             else if (bestTime != null)
               Text("Best: ${_formatTime(bestTime)}", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Back to Home"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(sudokuGameProvider.notifier).initNewGame(widget.difficulty);
              setState(() => _hasShownCompletionDialog = false);
            },
            child: const Text("New Game"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(sudokuGameProvider);
    
    // Robust Victory Check
    if (gameState.isCompleted && !_hasShownCompletionDialog) {
       Future.microtask(() => _showCompletionDialog(gameState.elapsedSeconds));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.difficulty.name.toUpperCase()} SUDOKU v2'),
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: Center(
               child: Text(
                 _formatTime(gameState.elapsedSeconds),
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
               ),
             ),
           )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     // Conflict Count or Hidden?
                     Chip(
                       avatar: Icon(
                         gameState.conflictIndexes.isEmpty ? Icons.check_circle : Icons.warning,
                         color: gameState.conflictIndexes.isEmpty ? Colors.green : Colors.red,
                         size: 20,
                       ),
                       label: Text(
                         gameState.conflictIndexes.isEmpty ? "No Errors" : "${gameState.conflictIndexes.length}",
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                     ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: gameState.undoStack.isEmpty 
                              ? null 
                              : () => ref.read(sudokuGameProvider.notifier).undo(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.redo),
                          onPressed: gameState.redoStack.isEmpty 
                              ? null 
                              : () => ref.read(sudokuGameProvider.notifier).redo(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SudokuBoardWidget(
                      board: gameState.board,
                      selectedIndex: gameState.selectedIndex ?? -1,
                      conflictIndexes: gameState.conflictIndexes,
                      onCellTap: (index) {
                        ref.read(sudokuGameProvider.notifier).selectCell(index);
                      },
                    ),
                  ),
                ),
              ),
              
              NumberPadWidget(
                onNumberTap: (number) {
                  HapticFeedback.selectionClick();
                  ref.read(sudokuGameProvider.notifier).inputNumber(number);
                },
                onEraseTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(sudokuGameProvider.notifier).erase();
                },
                onNoteToggleTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(sudokuGameProvider.notifier).toggleNoteMode();
                },
                isNoteMode: gameState.isNoteMode,
              ),
              const SizedBox(height: 32),
            ],
          ),
          
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false, 
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}
