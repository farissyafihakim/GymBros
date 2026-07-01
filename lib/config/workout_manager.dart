import 'package:GymBros/config/workout_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutManager {
  WorkoutManager._();
  static final WorkoutManager instance = WorkoutManager._();

  String? activeSessionId;
  String? templateId;
  final List<WorkoutLog> _logs = [];

  void startSession({String? templateId}) {
    this.templateId = templateId;
    _logs.clear();
  }

  void logSet(String exerciseName, int setNumber, {int? reps, double? weight}) {
    _logs.add(
      WorkoutLog(
        exerciseName: exerciseName,
        setNumber: setNumber,
        reps: reps,
        weight: weight,
      ),
    );
  }

  Future<void> saveSession() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    final session = await supabase
        .from('workout_sessions')
        .insert({
          'user_id': userId,
          'template_id': templateId,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final sessionId = session['id'];
    await supabase
        .from('workout_logs')
        .insert(_logs.map((l) => l.toJson(sessionId)).toList());

    _logs.clear();
    activeSessionId = null;
  }
}
