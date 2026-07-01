import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FitnessGoalsScreen extends StatefulWidget {
  const FitnessGoalsScreen({super.key});

  @override
  State<FitnessGoalsScreen> createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends State<FitnessGoalsScreen> {
  final supabase = Supabase.instance.client;

  List goals = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchGoals();
  }

  Future<void> fetchGoals() async {
    setState(() => loading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final data = await supabase
        .from('fitness_goals')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      goals = data;
      loading = false;
    });
  }

  Future<void> deleteGoal(String id) async {
    await supabase.from('fitness_goals').delete().eq('id', id);
    fetchGoals();
  }

  DateTime calculateDueDate(DateTime createdAt, int weeks) {
    return createdAt.add(Duration(days: weeks * 7));
  }

  void openCreateGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateGoalSheet(onSave: fetchGoals),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        title: const Text("Fitness Goals"),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC6F135),
        onPressed: openCreateGoal,
        child: const Icon(Icons.add, color: Colors.black),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : goals.isEmpty
          ? const Center(
              child: Text(
                "No goals yet. Tap + to add one.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final g = goals[index];

                final createdAt = DateTime.tryParse(g['created_at'] ?? '');
                final duration = g['duration_weeks'] ?? 4;

                final dueDate = createdAt != null
                    ? calculateDueDate(createdAt, duration)
                    : null;

                final progress = ((g['progress'] ?? 0) as num).toDouble().clamp(
                  0.0,
                  1.0,
                );

                return Dismissible(
                  key: Key(g['id'].toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => deleteGoal(g['id'].toString()),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E1E1E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          g['target_value'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 6),

                        if (dueDate != null)
                          Text(
                            "Due: ${dueDate.toLocal().toString().split(' ')[0]}",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 13,
                            ),
                          ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[900],
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFC6F135),
                                ),
                                minHeight: 8,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Text(
                              "${(progress * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────
// CREATE GOAL SHEET
// ─────────────────────────────────────────────

class _CreateGoalSheet extends StatefulWidget {
  final VoidCallback onSave;

  const _CreateGoalSheet({super.key, required this.onSave});

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final targetController = TextEditingController();
  final durationController = TextEditingController();

  bool saving = false;

  Future<void> saveGoal() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    await supabase.from('fitness_goals').insert({
      'user_id': user.id,
      'title': titleController.text,
      'target_value': targetController.text,
      'duration_weeks': int.tryParse(durationController.text) ?? 4,
      'progress': 0.0,
      'created_at': DateTime.now().toIso8601String(),
    });

    widget.onSave();

    if (mounted) Navigator.pop(context);

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Create Goal",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Goal Title",
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: targetController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Target",
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Duration (weeks)",
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC6F135),
              ),
              onPressed: saving ? null : saveGoal,
              child: saving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "Save Goal",
                      style: TextStyle(color: Colors.black),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
