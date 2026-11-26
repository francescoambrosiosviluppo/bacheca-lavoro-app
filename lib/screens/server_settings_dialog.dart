import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

/// Permette di impostare l'indirizzo del back-end (es. http://192.168.1.10:8090),
/// necessario quando l'app gira su uno smartphone reale nella stessa rete Wi-Fi.
/// Restituisce true se l'indirizzo è stato modificato.
Future<bool> showServerSettingsDialog(BuildContext context) async {
  final state = context.read<AppState>();
  final controller = TextEditingController(text: state.serverUrl);
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Indirizzo del server'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inserisci l\'indirizzo IP del computer su cui gira il back-end '
              '(lo stampa il server all\'avvio).',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'URL', hintText: 'http://192.168.1.10:8090'),
              keyboardType: TextInputType.url,
              autocorrect: false,
              validator: (v) {
                final uri = Uri.tryParse(v?.trim() ?? '');
                if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
                  return 'URL non valido (es. http://192.168.1.10:8090)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => controller.text = AppState.defaultServerUrl, child: const Text('Predefinito')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.of(ctx).pop(controller.text.trim());
          },
          child: const Text('Salva'),
        ),
      ],
    ),
  );

  if (result == null || result == state.serverUrl) return false;
  await state.setServerUrl(result);
  return true;
}
