import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutLogScreen extends StatefulWidget {
  final Map<String, dynamic>? template;
  const WorkoutLogScreen({super.key, this.template});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _ExerciseEntry {
  String name;
  List<_SetEntry> sets;
  _ExerciseEntry({required this.name, List<_SetEntry>? sets})
    : sets = sets ?? [_SetEntry()];
}

class _SetEntry {
  int? reps;
  double? weight;
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final List<_ExerciseEntry> _exercises = [];
  bool _isLoadingTemplate = false;
  bool _isSaving = false;

  static const bg = Color(0xFF0D0D0D);
  static const card = Color(0xFF1A1A1A);
  static const accent = Color(0xFFE8FF00);

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _loadTemplateExercises();
    }
  }

  Future<void> _loadTemplateExercises() async {
    setState(() => _isLoadingTemplate = true);
    try {
      final rows = await Supabase.instance.client
          .from('template_exercises')
          .select()
          .eq('template_id', widget.template!['id'])
          .order('order_index');

      setState(() {
        _exercises.addAll(
          List<Map<String, dynamic>>.from(
            rows,
          ).map((r) => _ExerciseEntry(name: r['exercise_name'])),
        );
        _isLoadingTemplate = false;
      });
    } catch (e) {
      setState(() => _isLoadingTemplate = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load exercises: $e')));
      }
    }
  }

  void _addExercise() {
    setState(() => _exercises.add(_ExerciseEntry(name: '')));
  }

  Future<void> _finishWorkout() async {
    final cleanExercises = _exercises
        .where((e) => e.name.trim().isNotEmpty)
        .toList();

    if (cleanExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise first')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final session = await supabase
          .from('workout_sessions')
          .insert({
            'user_id': userId,
            'template_id': widget.template?['id'],
            'ended_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final sessionId = session['id'];

      final logRows = <Map<String, dynamic>>[];
      for (final ex in cleanExercises) {
        for (int i = 0; i < ex.sets.length; i++) {
          final set = ex.sets[i];
          if (set.reps == null && set.weight == null) continue;
          logRows.add({
            'session_id': sessionId,
            'exercise_name': ex.name,
            'set_number': i + 1,
            'reps': set.reps,
            'weight': set.weight,
          });
        }
      }

      if (logRows.isNotEmpty) {
        await supabase.from('workout_logs').insert(logRows);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save workout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        title: Text(
          widget.template?['name'] ?? 'Freeform Workout',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: accent),
                  onPressed: _finishWorkout,
                ),
        ],
      ),
      body: _isLoadingTemplate
          ? const Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._exercises.asMap().entries.map(
                  (entry) => _buildExerciseCard(entry.value, entry.key),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _addExercise,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withOpacity(0.4)),
                    ),
                    child: const Center(
                      child: Text(
                        '+ Add Exercise',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseCard(_ExerciseEntry entry, int exIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: entry.name,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Exercise',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
            onChanged: (v) => entry.name = v,
          ),
          const SizedBox(height: 12),
          ...entry.sets.asMap().entries.map((setEntry) {
            final i = setEntry.key;
            final set = setEntry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      'Set ${i + 1}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberField(
                      label: 'Reps',
                      onChanged: (v) => set.reps = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberField(
                      label: 'Weight (kg)',
                      onChanged: (v) => set.weight = double.tryParse(v),
                    ),
                  ),
                ],
              ),
            );
          }),
          TextButton(
            onPressed: () => setState(() => entry.sets.add(_SetEntry())),
            style: TextButton.styleFrom(foregroundColor: accent),
            child: const Text('+ Add Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        isDense: true,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: accent),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
