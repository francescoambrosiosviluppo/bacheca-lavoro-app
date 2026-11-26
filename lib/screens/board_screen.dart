import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../main.dart' show routeObserver;
import '../models.dart';
import '../widgets/common.dart';
import 'company_home_screen.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';
import 'server_settings_dialog.dart';

/// Schermata pubblica: elenco degli annunci (R5). È la schermata iniziale.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> with RouteAware {
  late Future<List<Job>> _jobs;

  @override
  void initState() {
    super.initState();
    _jobs = _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Si torna alla bacheca da un'altra schermata: ricarica gli annunci.
  @override
  void didPopNext() => _refresh();

  Future<List<Job>> _load() => context.read<AppState>().api.listJobs();

  Future<void> _refresh() async {
    final f = _load();
    setState(() {
      _jobs = f;
    });
    await f.catchError((_) => <Job>[]);
  }

  Future<void> _openCompanyArea() async {
    final loggedIn = context.read<AppState>().isLoggedIn;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => loggedIn ? const CompanyHomeScreen() : const LoginScreen()));
    if (mounted) _refresh();
  }

  Future<void> _openSettings() async {
    final changed = await showServerSettingsDialog(context);
    if (changed && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Lavoro'),
        actions: [
          IconButton(
            tooltip: 'Impostazioni server',
            icon: const Icon(Icons.settings_ethernet),
            onPressed: _openSettings,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _openCompanyArea,
              icon: Icon(state.isLoggedIn ? Icons.business_center : Icons.login),
              label: Text(state.isLoggedIn ? 'Area riservata' : 'Area aziende'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Job>>(
          future: _jobs,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ErrorView(message: snap.error.toString(), onRetry: _refresh);
            }
            final jobs = snap.data!;
            if (jobs.isEmpty) {
              return const EmptyView(
                icon: Icons.work_outline,
                title: 'Nessun annuncio pubblicato',
                subtitle: 'Torna più tardi oppure tira verso il basso per aggiornare.',
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => JobCard(
                job: jobs[i],
                onTap: () async {
                  await Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: jobs[i].id)));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.onTap, this.trailing});

  final Job job;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (job.location != null) job.location!,
      if (job.contractType != null) job.contractType!,
      'Pubblicato il ${formatDate(job.createdAt)}',
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text(job.companyName.isNotEmpty ? job.companyName[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      job.companyName,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(meta.join(' · '), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
