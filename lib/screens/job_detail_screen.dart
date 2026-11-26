import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'apply_screen.dart';

/// Dettaglio di un annuncio (R5) con il pulsante per candidarsi (R6).
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Future<Job> _job;

  @override
  void initState() {
    super.initState();
    _job = context.read<AppState>().api.getJob(widget.jobId);
  }

  void _retry() => setState(() {
    _job = context.read<AppState>().api.getJob(widget.jobId);
  });

  @override
  Widget build(BuildContext context) {
    // Le aziende non si candidano: il pulsante è visibile solo agli utenti pubblici.
    final isCompany = context.watch<AppState>().isLoggedIn;
    return FutureBuilder<Job>(
      future: _job,
      builder: (context, snap) {
        final job = snap.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Dettaglio annuncio')),
          body: switch (snap) {
            _ when snap.connectionState != ConnectionState.done => const Center(child: CircularProgressIndicator()),
            _ when snap.hasError => ErrorView(message: snap.error.toString(), onRetry: _retry),
            _ => _JobDetailBody(job: job!),
          },
          bottomNavigationBar: job == null || isCompany
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Candidati'),
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplyScreen(job: job))),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  const _JobDetailBody({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(job.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(job.companyName, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (job.location != null) Chip(avatar: const Icon(Icons.place, size: 18), label: Text(job.location!)),
            if (job.contractType != null)
              Chip(avatar: const Icon(Icons.badge_outlined, size: 18), label: Text(job.contractType!)),
            Chip(avatar: const Icon(Icons.event, size: 18), label: Text(formatDate(job.createdAt))),
          ],
        ),
        const Divider(height: 32),
        Text('Descrizione', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SelectableText(job.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
      ],
    );
  }
}
