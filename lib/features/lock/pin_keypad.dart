/// Tastierino numerico e indicatore delle cifre inserite.
///
/// Si usa un tastierino dedicato invece della tastiera di sistema: le cifre
/// restano grandi e raggiungibili con una mano, e non passano dal
/// suggerimento automatico del testo, che potrebbe conservarle.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
  });

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = error ? scheme.error : scheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? activeColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? activeColor : scheme.outline,
              width: 1.6,
            ),
          ),
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    this.enabled = true,
    this.canSubmit = false,
    this.submitLabel = 'Conferma',
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool enabled;
  final bool canSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) _Key(digit: d, onTap: enabled ? onDigit : null)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 84, height: 68),
            _Key(digit: '0', onTap: enabled ? onDigit : null),
            SizedBox(
              width: 84,
              height: 68,
              child: IconButton(
                onPressed: enabled ? onBackspace : null,
                icon: const Icon(Icons.backspace_outlined),
                tooltip: 'Cancella una cifra',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 252,
          child: FilledButton(
            onPressed: enabled && canSubmit ? onSubmit : null,
            child: Text(submitLabel),
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.digit, this.onTap});

  final String digit;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 68,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: OutlinedButton(
          onPressed: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!(digit);
                },
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            digit,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}
