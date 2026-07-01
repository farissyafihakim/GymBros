class WorkoutTemplate {
  final String id, name, category;
  final bool isBuiltin;
  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.isBuiltin,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      WorkoutTemplate(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        isBuiltin: json['is_builtin'],
      );
}

class WorkoutLog {
  final String exerciseName;
  final int setNumber;
  int? reps;
  double? weight;
  WorkoutLog({
    required this.exerciseName,
    required this.setNumber,
    this.reps,
    this.weight,
  });

  Map<String, dynamic> toJson(String sessionId) => {
    'session_id': sessionId,
    'exercise_name': exerciseName,
    'set_number': setNumber,
    'reps': reps,
    'weight': weight,
  };
}
