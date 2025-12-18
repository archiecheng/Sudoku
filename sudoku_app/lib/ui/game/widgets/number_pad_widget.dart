import 'package:flutter/material.dart';

class NumberPadWidget extends StatelessWidget {
  final Function(int) onNumberTap;
  final VoidCallback onEraseTap;
  final VoidCallback onNoteToggleTap;
  final bool isNoteMode;

  const NumberPadWidget({
    super.key,
    required this.onNumberTap,
    required this.onEraseTap,
    required this.onNoteToggleTap,
    required this.isNoteMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Numbers 1-9
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(9, (index) {
              int number = index + 1;
              return _buildNumberBtn(context, number);
            }),
          ),
        ),
        const SizedBox(height: 24),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             _buildControlBtn(
              context,
              icon: Icons.edit,
              label: 'Notes',
              isActive: isNoteMode,
              onTap: onNoteToggleTap,
            ),
             _buildControlBtn(
              context,
              icon: Icons.backspace_outlined,
              label: 'Erase',
              onTap: onEraseTap,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildNumberBtn(BuildContext context, int number) {
    return SizedBox(
      width: 60,
      height: 60,
      child: FilledButton.tonal(
        onPressed: () => onNumberTap(number),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          '$number',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildControlBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: isActive ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            foregroundColor: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fixedSize: const Size(56, 56),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
