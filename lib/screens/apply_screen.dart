import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Form di candidatura del candidato (R6): dati anagrafici + curriculum.
class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key, required this.job});

  final Job job;

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  static const _maxBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  String? _cvName;
  Uint8List? _cvBytes;
  bool _cvMissing = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCv() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Seleziona il curriculum',
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
      if (files.isEmpty) return; // selezione annullata
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) {
        if (mounted) showSnack(context, 'Il file supera i 10 MB.', error: true);
        return;
      }
      setState(() {
        _cvName = file.name;
        _cvBytes = bytes;
        _cvMissing = false;
      });
    } catch (e) {
      if (mounted) showSnack(context, 'Impossibile leggere il file: $e', error: true);
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _cvMissing = _cvBytes == null);
    if (!valid || _cvBytes == null) return;

    setState(() => _busy = true);
    try {
      await context.read<AppState>().api.apply(
        jobId: widget.job.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        message: _message.text.trim(),
        cvFilename: _cvName!,
        cvBytes: _cvBytes!,
      );
      if (!mounted) return;
      await _showConfirmation();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showConfirmation() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle, size: 48, color: Theme.of(ctx).colorScheme.primary),
        title: const Text('Candidatura inviata!'),
        content: Text(
          'Grazie ${_firstName.text.trim()}, la tua candidatura per "${widget.job.title}" '
          'presso ${widget.job.companyName} è stata registrata correttamente.',
          textAlign: TextAlign.center,
        ),
        actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Torna alla bacheca'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.job.title, style: theme.textTheme.titleLarge),
            Text(widget.job.companyName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Nome *', prefixIcon: Icon(Icons.person_outline)),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredValidator(v, 'Nome'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Cognome *', prefixIcon: Icon(Icons.person_outline)),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredValidator(v, 'Cognome'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.alternate_email)),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Telefono (facoltativo)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Messaggio di presentazione (facoltativo)',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            _CvPickerTile(name: _cvName, error: _cvMissing, onPick: _busy ? null : _pickCv),
            const SizedBox(height: 28),
            BusyButton(busy: _busy, onPressed: _submit, label: 'Invia candidatura', icon: Icons.send),
          ],
        ),
      ),
    );
  }
}

class _CvPickerTile extends StatelessWidget {
  const _CvPickerTile({required this.name, required this.error, required this.onPick});

  final String? name;
  final bool error;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = error ? scheme.error : scheme.outline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListTile(
            leading: Icon(name == null ? Icons.upload_file : Icons.picture_as_pdf, color: scheme.primary),
            title: Text(name ?? 'Curriculum *'),
            subtitle: Text(name == null ? 'PDF, DOC o DOCX — max 10 MB' : 'Tocca "Cambia" per sostituirlo'),
            trailing: TextButton(onPressed: onPick, child: Text(name == null ? 'Allega' : 'Cambia')),
            onTap: onPick,
          ),
        ),
        if (error)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text('Allega il curriculum', style: TextStyle(color: scheme.error, fontSize: 12)),
          ),
      ],
    );
  }
}
