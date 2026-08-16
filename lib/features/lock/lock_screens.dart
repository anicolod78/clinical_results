/// Schermate di configurazione e sblocco del codice di sicurezza.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';
import '../../core/security/pin_policy.dart';
import 'pin_keypad.dart';

/// Primo avvio: scelta del codice, con conferma.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.error, this.busy = false});

  final String? error;
  final bool busy;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmation = '';
  bool _confirming = false;

  String get _current => _confirming ? _confirmation : _pin;

  void _addDigit(String d) {
    if (_current.length >= PinPolicy.maxLength) return;
    setState(() {
      if (_confirming) {
        _confirmation += d;
      } else {
        _pin += d;
      }
    });
  }

  void _backspace() {
    if (_current.isEmpty) {
      if (_confirming) setState(() => _confirming = false);
      return;
    }
    setState(() {
      if (_confirming) {
        _confirmation = _confirmation.substring(0, _confirmation.length - 1);
      } else {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _submit() {
    if (!_confirming) {
      setState(() => _confirming = true);
      return;
    }
    ref.read(sessionProvider.notifier).setupPin(_pin, _confirmation);
    setState(() {
      _pin = '';
      _confirmation = '';
      _confirming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final policyError = _confirming ? null : PinPolicy.validate(_pin);
    final canSubmit = _confirming
        ? _confirmation.length >= PinPolicy.minLength
        : policyError == null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _confirming ? 'Ripeti il codice' : 'Scegli un codice',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _confirming
                        ? 'Inseriscilo una seconda volta per conferma.'
                        : 'Protegge i referti conservati sul dispositivo. '
                              'Verrà richiesto a ogni accesso.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  PinDots(
                    length: _current.length < PinPolicy.minLength
                        ? PinPolicy.minLength
                        : _current.length,
                    filled: _current.length,
                    error: widget.error != null,
                  ),
                  const SizedBox(height: 16),
                  _Message(
                    text: widget.error ??
                        (_pin.isNotEmpty && !_confirming ? policyError : null),
                    isError: true,
                  ),
                  const SizedBox(height: 8),
                  if (widget.busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Preparazione dell archivio cifrato…'),
                        ],
                      ),
                    )
                  else
                    PinKeypad(
                      onDigit: _addDigit,
                      onBackspace: _backspace,
                      onSubmit: _submit,
                      canSubmit: canSubmit,
                      submitLabel: _confirming ? 'Conferma' : 'Avanti',
                    ),
                  const SizedBox(height: 24),
                  _SecurityNote(
                    text: 'Il codice non viene salvato da nessuna parte. '
                        'Se lo dimentichi i referti non sono più '
                        'recuperabili: non esiste un modo per aggirarlo.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accesso a un archivio già configurato.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({
    super.key,
    this.error,
    this.busy = false,
    this.lockoutUntil,
    this.failedAttempts = 0,
  });

  final String? error;
  final bool busy;
  final DateTime? lockoutUntil;
  final int failedAttempts;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  String _pin = '';
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(UnlockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockoutUntil != widget.lockoutUntil) {
      // Il codice inserito va scartato quando scatta l'attesa, altrimenti
      // resterebbe visibile sullo schermo per tutta la sua durata.
      _pin = '';
      _syncTicker();
    }
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (_remaining() > Duration.zero) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_remaining() <= Duration.zero) _ticker?.cancel();
      });
    }
  }

  Duration _remaining() {
    final until = widget.lockoutUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _submit() {
    final pin = _pin;
    setState(() => _pin = '');
    ref.read(sessionProvider.notifier).unlock(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waiting = _remaining();
    final isWaiting = waiting > Duration.zero;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Risultati clinici',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Inserisci il codice di sicurezza.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PinDots(
                    length: _pin.length < PinPolicy.minLength
                        ? PinPolicy.minLength
                        : _pin.length,
                    filled: _pin.length,
                    error: widget.error != null,
                  ),
                  const SizedBox(height: 16),
                  if (isWaiting)
                    _Message(
                      text: 'Troppi tentativi errati. '
                          'Riprova fra ${_format(waiting)}.',
                      isError: true,
                    )
                  else
                    _Message(text: widget.error, isError: true),
                  const SizedBox(height: 8),
                  if (widget.busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Apertura dell archivio…'),
                        ],
                      ),
                    )
                  else
                    PinKeypad(
                      onDigit: (d) {
                        if (_pin.length >= PinPolicy.maxLength) return;
                        setState(() => _pin += d);
                      },
                      onBackspace: () {
                        if (_pin.isEmpty) return;
                        setState(
                          () => _pin = _pin.substring(0, _pin.length - 1),
                        );
                      },
                      onSubmit: _submit,
                      enabled: !isWaiting,
                      canSubmit: _pin.length >= PinPolicy.minLength,
                      submitLabel: 'Sblocca',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _format(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes min ${seconds.toString().padLeft(2, '0')} s';
  }
}

class _Message extends StatelessWidget {
  const _Message({this.text, this.isError = false});

  final String? text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox(height: 20);
    final theme = Theme.of(context);
    return SizedBox(
      child: Text(
        text!,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError ? theme.colorScheme.error : null,
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
