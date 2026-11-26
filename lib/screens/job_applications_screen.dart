import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'application_detail_screen.dart';

/// Candidature ricevute per un annuncio dell'azienda (R7).
class JobApplicationsScreen extends StatefulWidget {
  const JobApplicationsScreen({super.key, required this.job});

  final Job job;

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  late Future<List<JobApplication>> _apps;

  @override
  void initState() {
    super.initState();
    _apps = _load();
  }

  Future<List<JobApplication>> _load() async {
    try {
      return await context.read<AppState>().api.applicationsForJob(widget.job.id);
    } catch (e) {
      if (mounted && handleAuthError(context, e)) return [];
      rethrow;
    }
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() {
      _apps = f;
    });
    await f.catchError((_) => <JobApplication>[]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidature ricevute')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.job.title, style: theme.textTheme.titleLarge),
                Text('Pubblicato il ${formatDate(widget.job.createdAt)}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<JobApplication>>(
                future: _apps,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
                  final apps = snap.data!;
                  if (apps.isEmpty) {
                    return const EmptyView(
                      icon: Icons.inbox_outlined,
                      title: 'Nessuna candidatura ricevuta',
                      subtitle: 'Le candidature compariranno qui appena arrivano.',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: apps.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final a = apps[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: CircleAvatar(child: Text('${a.firstName[0]}${a.lastName[0]}'.toUpperCase())),
                        title: Text(a.fullName),
                        subtitle: Text('${a.email}\nRicevuta il ${formatDateTime(a.createdAt)}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: a.id))),
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
