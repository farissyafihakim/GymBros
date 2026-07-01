import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  static const bg = Color(0xFF0D0D0D);
  static const card = Color(0xFF1A1A1A);
  static const accent = Color(0xFFE8FF00);

  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _fetchSessions();
  }

  Future<List<Map<String, dynamic>>> _fetchSessions() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final rows = await Supabase.instance.client
        .from('workout_sessions')
        .select('id, started_at, ended_at, workout_templates(name)')
        .eq('user_id', userId)
        .order('started_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async {
    setState(() {
      _sessionsFuture = _fetchSessions();
    });
    await _sessionsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Workout History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load history: ${snapshot.error}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'No workouts logged yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            color: accent,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, i) => _buildSessionCard(sessions[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> s) {
    final templateName = s['workout_templates']?['name'] ?? 'Freeform';
    final date = DateTime.parse(s['started_at']);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: accent,
          iconColor: accent,
          title: Text(
            templateName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(dateStr, style: const TextStyle(color: Colors.grey)),
          children: [
            FutureBuilder<List<dynamic>>(
              future: Supabase.instance.client
                  .from('workout_logs')
                  .select()
                  .eq('session_id', s['id'])
                  .order('set_number'),
              builder: (context, logSnap) {
                if (logSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: accent),
                  );
                }
                final logs = logSnap.data ?? [];
                if (logs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No sets recorded',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final grouped = <String, List<dynamic>>{};
                for (final l in logs) {
                  grouped.putIfAbsent(l['exercise_name'], () => []).add(l);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: grouped.entries.map((e) {
                      final setsText = e.value
                          .map((set) {
                            final reps = set['reps'] ?? '-';
                            final weight = set['weight'] ?? '-';
                            return '${reps}x${weight}kg';
                          })
                          .join(', ');
                      return ListTile(
                        dense: true,
                        title: Text(
                          e.key,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          setsText,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
