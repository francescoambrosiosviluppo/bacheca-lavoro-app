import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/common.dart';

/// Creazione di un nuovo annuncio (R4). Restituisce il [Job] pubblicato.
class NewJobScreen extends StatefulWidget {
  const NewJobScreen({super.key});

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  static const _contractTypes = [
    'Tempo indeterminato',
    'Tempo determinato',
    'Stage / Tirocinio',
    'Apprendistato',
    'Part-time',
    'Freelance',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String? _contractType;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final job = await context.read<AppState>().api.createJob(
        title: _title.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        contractType: _contractType,
      );
      if (mounted) Navigator.of(context).pop(job);
    } catch (e) {
      if (!mounted || handleAuthError(context, e)) return;
      showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titolo *', hintText: 'Es. Sviluppatore Flutter junior'),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 120,
              validator: (v) => requiredValidator(v, 'Titolo'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Descrizione *',
                hintText: 'Mansioni, requisiti, cosa offrite...',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 5,
              maxLines: 12,
              validator: (v) => requiredValidator(v, 'Descrizione'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Sede (facoltativa)',
                hintText: 'Es. Salerno / Remoto',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _contractType,
              decoration: const InputDecoration(
                labelText: 'Tipo di contratto (facoltativo)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [for (final t in _contractTypes) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setState(() => _contractType = v),
            ),
            const SizedBox(height: 28),
            BusyButton(busy: _busy, onPressed: _publish, label: 'Pubblica annuncio', icon: Icons.campaign),
          ],
        ),
      ),
    );
  }
}
