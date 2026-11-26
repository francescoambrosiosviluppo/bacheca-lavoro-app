import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

String formatDate(DateTime d) => _dateFormat.format(d);
String formatDateTime(DateTime d) => _dateTimeFormat.format(d);

void showSnack(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Se la sessione non è più valida (401) chiude l'area riservata
/// e torna alla bacheca pubblica. Restituisce true se l'ha gestito.
bool handleAuthError(BuildContext context, Object error) {
  if (error is ApiException && error.isUnauthorized) {
    context.read<AppState>().clearSession();
    Navigator.of(context).popUntil((r) => r.isFirst);
    showSnack(context, 'Sessione scaduta: effettua di nuovo il login.', error: true);
    return true;
  }
  return false;
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Riprova')),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ListView così il pull-to-refresh funziona anche quando la lista è vuota.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      children: [
        Icon(icon, size: 56, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// Riga "etichetta: valore" con icona, usata nei dettagli.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
                SelectableText(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottone che mostra uno spinner mentre l'operazione è in corso.
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.busy, required this.onPressed, required this.label, this.icon});

  final bool busy;
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon ?? Icons.check),
        label: Text(label),
      ),
    );
  }
}

String? requiredValidator(String? v, String field) => (v == null || v.trim().isEmpty) ? '$field obbligatorio' : null;

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email obbligatoria';
  if (!_emailRegex.hasMatch(v.trim())) return 'Email non valida';
  return null;
}
