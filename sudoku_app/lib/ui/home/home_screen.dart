
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logic/sudoku_structs.dart';
import '../../core/logic/game_notifier.dart';
import '../../core/logic/sudoku_repository.dart';
import '../../core/service/persistence_service.dart';
import '../game/game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // We need persistence service here to check 'hasSave'. 
  // Ideally, this state lives in a riverpod provider, but for simplicity we instantiate logic here or use a FutureProvider.
  // Let's adhere to "Use Notifier for Logic". 
  // We can ask notifier if there is a save, but notifier acts on state.
  // Let's assume PersistenceService is singleton-like or accessible.
  // For Quick implementation:
  
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  Future<void> _checkSave() async {
    // A bit hacky to instantiate Repo just for this check, but efficient enough for MVP
    final service = PersistenceService(SudokuPuzzleRepository());
    final has = await service.hasSave();
    if (mounted) setState(() => _hasSave = has);
  }

  void _startGame(Difficulty? difficulty, {bool isDaily = false, bool isContinue = false}) {
    if (isContinue) {
      // Logic: Push GameScreen, then inside GameScreen init, tell notifier to resume.
      // Current GameScreen init calls 'initNewGame'. We need to change that flow.
      // GameScreen expects a difficulty. If continuing, we override.
      // Refactor GameScreen/Notifier communication.
      // Option: Pass a flag to GameScreen.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GameScreen(difficulty: Difficulty.easy, isResume: true)),
      ).then((_) => _checkSave());
    } else if (isDaily) {
      // Daily
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GameScreen(difficulty: Difficulty.medium, isDaily: true)),
      ).then((_) => _checkSave()); // Returning might have cleared save if completed (though Daily doesn't use standard save slot?)
      // Daily uses standard save slot effectively in this simple impl.
    } else {
      // New Game
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GameScreen(difficulty: difficulty!)),
      ).then((_) => _checkSave());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Light background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_on, size: 80, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'SUDOKU',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            const SizedBox(height: 48),

            // Continue Button
            SizedBox(
              width: 200,
              child: FilledButton.tonal(
                onPressed: _hasSave ? () => _startGame(null, isContinue: true) : null,
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Daily Button
            SizedBox(
              width: 200,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                onPressed: () => _startGame(null, isDaily: true),
                label: const Text('Daily Challenge'),
              ),
            ),
            const SizedBox(height: 32),

            // New Game Section
            Text("New Game", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DifficultyBtn("Easy", Difficulty.easy, Colors.green, () => _startGame(Difficulty.easy)),
                const SizedBox(width: 16),
                _DifficultyBtn("Medium", Difficulty.medium, Colors.orange, () => _startGame(Difficulty.medium)),
                const SizedBox(width: 16),
                _DifficultyBtn("Hard", Difficulty.hard, Colors.red, () => _startGame(Difficulty.hard)),
              ],
            ),
            
            const SizedBox(height: 48),
            // Reset Save
            if (_hasSave)
              TextButton(
                onPressed: () async {
                   final service = PersistenceService(SudokuPuzzleRepository());
                   await service.clearSave();
                   _checkSave();
                },
                child: const Text("Clear Saved Game", style: TextStyle(color: Colors.grey)),
              )
          ],
        ),
      ),
    );
  }
}

class _DifficultyBtn extends StatelessWidget {
  final String label;
  final Difficulty difficulty;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyBtn(this.label, this.difficulty, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
