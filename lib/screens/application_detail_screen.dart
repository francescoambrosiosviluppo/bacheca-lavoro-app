import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Dati del candidato e apertura del curriculum allegato (R7).
class ApplicationDetailScreen extends StatefulWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final int applicationId;

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  late Future<JobApplication> _app;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _app = _load();
  }

  Future<JobApplication> _load() async {
    try {
      return await context.read<AppState>().api.getApplication(widget.applicationId);
    } catch (e) {
      if (mounted) handleAuthError(context, e);
      rethrow;
    }
  }

  /// Scarica il CV (con il token dell'azienda) in una cartella temporanea
  /// e lo apre con il visualizzatore del telefono.
  Future<void> _openCv(JobApplication app) async {
    setState(() => _opening = true);
    try {
      final bytes = await context.read<AppState>().api.downloadCv(app.id);
      final dir = await getTemporaryDirectory();
      final safeName = app.cvFilename.replaceAll(RegExp(r'[^\w.\- ]'), '_');
      final file = File('${dir.path}/cv_${app.id}_$safeName');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        showSnack(context, 'Impossibile aprire il file: ${result.message}', error: true);
      }
    } catch (e) {
      if (!mounted || handleAuthError(context, e)) return;
      showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: FutureBuilder<JobApplication>(
        future: _app,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorView(
              message: snap.error.toString(),
              onRetry: () => setState(() {
                _app = _load();
              }),
            );
          }
          final a = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text('${a.firstName[0]}${a.lastName[0]}'.toUpperCase(), style: theme.textTheme.titleLarge),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.fullName, style: theme.textTheme.headlineSmall),
                        Text('Candidatura per: ${a.jobTitle}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              InfoRow(icon: Icons.person_outline, label: 'Nome', value: a.firstName),
              InfoRow(icon: Icons.person_outline, label: 'Cognome', value: a.lastName),
              InfoRow(icon: Icons.alternate_email, label: 'Email', value: a.email),
              if (a.phone != null) InfoRow(icon: Icons.phone_outlined, label: 'Telefono', value: a.phone!),
              InfoRow(icon: Icons.schedule, label: 'Ricevuta il', value: formatDateTime(a.createdAt)),
              if (a.message != null) InfoRow(icon: Icons.notes, label: 'Messaggio', value: a.message!),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary, size: 32),
                  title: const Text('Curriculum'),
                  subtitle: Text(a.cvFilename),
                ),
              ),
              const SizedBox(height: 16),
              BusyButton(
                busy: _opening,
                onPressed: () => _openCv(a),
                label: 'Apri curriculum',
                icon: Icons.open_in_new,
              ),
            ],
          );
        },
      ),
    );
  }
}
