int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
int? _intOrNull(dynamic v) => v is num ? v.toInt() : null;

class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    this.description = '',
    this.category,
    this.videoUrl,
    this.imageUrl,
    this.precautions,
  });

  final String id;
  final String title;
  final String description;
  final String? category;
  final String? videoUrl;
  final String? imageUrl;
  final String? precautions;

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        category: j['category'] as String?,
        videoUrl: j['videoUrl'] as String?,
        imageUrl: j['imageUrl'] as String?,
        precautions: j['precautions'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category ?? '',
        'videoUrl': videoUrl ?? '',
        'imageUrl': imageUrl ?? '',
        'precautions': precautions ?? '',
      };
}

/// An exercise prescribed to a patient (sets, reps, schedule).
class ExerciseAssignment {
  const ExerciseAssignment({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    this.durationSeconds,
    this.restSeconds,
    this.daysOfWeek = const [],
    this.startDate,
    this.endDate,
    this.completed = false,
  });

  final String id;
  final Exercise exercise;
  final int sets;
  final int reps;
  final int? durationSeconds;
  final int? restSeconds;

  /// 1 = Monday ... 7 = Sunday. Empty means every day.
  final List<int> daysOfWeek;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Patient endpoints only: whether it was completed on the requested day.
  final bool completed;

  factory ExerciseAssignment.fromJson(Map<String, dynamic> j) {
    final ex = j['exercise'];
    return ExerciseAssignment(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      exercise: ex is Map<String, dynamic>
          ? Exercise.fromJson(ex)
          : Exercise(
              id: (j['exerciseId'] ?? '').toString(),
              title: (j['exerciseTitle'] ?? 'Exercise').toString()),
      sets: _int(j['sets'], 1),
      reps: _int(j['reps'], 1),
      durationSeconds: _intOrNull(j['durationSeconds']),
      restSeconds: _intOrNull(j['restSeconds']),
      daysOfWeek: (j['daysOfWeek'] as List?)
              ?.map((e) => _int(e))
              .where((e) => e >= 1 && e <= 7)
              .toList() ??
          const [],
      startDate: j['startDate'] != null
          ? DateTime.tryParse(j['startDate'].toString())?.toLocal()
          : null,
      endDate: j['endDate'] != null
          ? DateTime.tryParse(j['endDate'].toString())?.toLocal()
          : null,
      completed: j['completed'] as bool? ?? false,
    );
  }
}

class Completion {
  const Completion({
    required this.id,
    required this.assignmentId,
    required this.exerciseTitle,
    required this.completedAt,
    this.painLevel,
    this.notes,
  });

  final String id;
  final String assignmentId;
  final String exerciseTitle;
  final DateTime completedAt;
  final int? painLevel;
  final String? notes;

  factory Completion.fromJson(Map<String, dynamic> j) {
    final ex = j['exercise'];
    return Completion(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      assignmentId: (j['assignmentId'] ?? j['assignment'] ?? '').toString(),
      exerciseTitle: (j['exerciseTitle'] ??
              (ex is Map ? ex['title'] : null) ??
              'Exercise')
          .toString(),
      completedAt:
          DateTime.tryParse((j['completedAt'] ?? '').toString())?.toLocal() ??
              DateTime.now(),
      painLevel: _intOrNull(j['painLevel']),
      notes: j['notes'] as String?,
    );
  }
}
