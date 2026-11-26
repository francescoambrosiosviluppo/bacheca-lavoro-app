import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'board_screen.dart';
import 'job_applications_screen.dart';
import 'new_job_screen.dart';

/// Area riservata dell'azienda: i propri annunci (R7), nuovo annuncio (R4), logout (R3).
class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  late Future<List<Job>> _jobs;

  @override
  void initState() {
    super.initState();
    _jobs = _load();
  }

  Future<List<Job>> _load() async {
    try {
      return await context.read<AppState>().api.myJobs();
    } catch (e) {
      if (mounted && handleAuthError(context, e)) return [];
      rethrow;
    }
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() {
      _jobs = f;
    });
    await f.catchError((_) => <Job>[]);
  }

  Future<void> _newJob() async {
    final job = await Navigator.of(context).push<Job>(MaterialPageRoute(builder: (_) => const NewJobScreen()));
    if (job == null || !mounted) return;
    _refresh();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Annuncio "${job.title}" pubblicato in bacheca.'),
          action: SnackBarAction(label: 'Vedi bacheca', onPressed: _goToBoard),
        ),
      );
  }

  void _goToBoard() => Navigator.of(context).popUntil((r) => r.isFirst);

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Esci'),
        content: const Text('Vuoi uscire dal tuo account?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Esci')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<AppState>().logout();
    // Torna alla schermata pubblica rimuovendo tutte le schermate riservate.
    navigator.popUntil((r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Logout effettuato.')));
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<AppState>().company;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area riservata'),
        actions: [
          IconButton(tooltip: 'Bacheca pubblica', icon: const Icon(Icons.dashboard_outlined), onPressed: _goToBoard),
          IconButton(tooltip: 'Logout', icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newJob,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo annuncio'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.primaryContainer,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Icon(Icons.business, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company?.name ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                      Text(
                        company?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('I miei annunci', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Job>>(
                future: _jobs,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
                  final jobs = snap.data!;
                  if (jobs.isEmpty) {
                    return const EmptyView(
                      icon: Icons.post_add,
                      title: 'Non hai ancora pubblicato annunci',
                      subtitle: 'Tocca "Nuovo annuncio" per pubblicare il primo.',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final job = jobs[i];
                      return JobCard(
                        job: job,
                        trailing: Badge.count(
                          count: job.applicationsCount,
                          isLabelVisible: job.applicationsCount > 0,
                          child: const Icon(Icons.people_outline),
                        ),
                        onTap: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => JobApplicationsScreen(job: job)));
                          if (mounted) _refresh();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
