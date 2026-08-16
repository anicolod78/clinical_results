/// Impostazioni di sicurezza e gestione dell'archivio.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/appearance.dart';
import '../../app/session.dart';
import '../../core/db/database.dart';
import '../../core/security/pin_policy.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          _SectionTitle('Aspetto'),
          const _ThemeModeTile(),
          const Divider(),
          _SectionTitle('Sicurezza'),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Cambia codice di sicurezza'),
            subtitle: const Text('I referti restano al loro posto'),
            onTap: () => _changePin(context, ref),
          ),
          const _WipePolicyTile(),
          const Divider(),
          _SectionTitle('Come sono protetti i dati'),
          const _EncryptionStatus(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'I referti sono conservati in un database cifrato per intero '
              'sul dispositivo. La chiave che lo apre è protetta dal codice '
              'di sicurezza e custodita nell archivio protetto del sistema.\n\n'
              'Il riconoscimento del testo avviene sul dispositivo: le '
              'immagini dei referti non vengono inviate ad alcun servizio. '
              'I backup automatici verso il cloud sono disattivati.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(),
          _SectionTitle('Archivio'),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: theme.colorScheme.error),
            title: Text(
              'Elimina tutti i dati',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text(
              'Cancella referti, pazienti e codice di sicurezza',
            ),
            onTap: () => _destroy(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (_) => const _ChangePinDialog(),
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(sessionProvider.notifier)
        .changePin(result.current, result.next);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Codice aggiornato.')),
    );
  }

  Future<void> _destroy(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare tutto?'),
        content: const Text(
          'Verranno cancellati tutti i pazienti, i referti e il codice di '
          'sicurezza. Non esiste alcun modo per recuperarli in seguito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina tutto'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(sessionProvider.notifier).destroyEverything();
  }
}

/// Stato effettivo della cifratura dell'archivio.
///
/// Non è una nota informativa ma una verifica: il valore viene chiesto al
/// database aperto. Sul browser la cifratura dipende da quali file system
/// virtuali il modulo WebAssembly riesce ad avvolgere, e l'esito si conosce
/// soltanto all'apertura. Dichiararlo è l'unico modo onesto di trattarlo:
/// un archivio sanitario non protetto che si comporta come se lo fosse è
/// peggio di uno dichiaratamente non protetto.
class _EncryptionStatus extends StatelessWidget {
  const _EncryptionStatus();

  @override
  Widget build(BuildContext context) {
    final encrypted = AppDatabase.isEncrypted;
    final scheme = Theme.of(context).colorScheme;
    final color = encrypted ? scheme.primary : scheme.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.07),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            encrypted ? Icons.lock_outline : Icons.lock_open_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  encrypted
                      ? 'Archivio cifrato'
                      : 'Archivio NON cifrato',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  encrypted
                      ? 'Il database è protetto: senza il codice di sicurezza '
                            'i dati non sono leggibili nemmeno estraendo il file.'
                      : 'Su questa piattaforma la cifratura non è disponibile. '
                            'Non inserire referti reali: i dati sono leggibili '
                            'da chiunque abbia accesso al browser.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scelta del tema.
class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: [
              for (final mode in ThemeMode.values)
                ButtonSegment(
                  value: mode,
                  icon: Icon(themeModeIcon(mode)),
                  label: Text(themeModeLabel(mode)),
                ),
            ],
            selected: {current},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ],
      ),
    );
  }
}

/// Cancellazione automatica dopo troppi tentativi errati.
class _WipePolicyTile extends ConsumerStatefulWidget {
  const _WipePolicyTile();

  @override
  ConsumerState<_WipePolicyTile> createState() => _WipePolicyTileState();
}

class _WipePolicyTileState extends ConsumerState<_WipePolicyTile> {
  int? _limit;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ref.read(vaultProvider).wipeAfterAttempts();
    if (!mounted) return;
    setState(() {
      _limit = value;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    return SwitchListTile(
      secondary: const Icon(Icons.lock_reset_outlined),
      title: const Text('Cancella i dati dopo 20 errori'),
      subtitle: const Text(
        'Protegge in caso di furto, ma un uso distratto può far perdere '
        'tutto lo storico',
      ),
      value: _limit != null,
      onChanged: (enabled) async {
        await ref.read(vaultProvider).setWipeAfterAttempts(enabled ? 20 : null);
        if (mounted) setState(() => _limit = enabled ? 20 : null);
      },
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog();

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final policyError = PinPolicy.validate(_next.text);
    if (policyError != null) {
      setState(() => _error = policyError);
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'I due nuovi codici non coincidono.');
      return;
    }
    Navigator.of(context).pop((current: _current.text, next: _next.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambia codice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_current, 'Codice attuale'),
          const SizedBox(height: 12),
          _field(_next, 'Nuovo codice'),
          const SizedBox(height: 12),
          _field(_confirm, 'Ripeti il nuovo codice'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Cambia')),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: PinPolicy.maxLength,
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.8,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
