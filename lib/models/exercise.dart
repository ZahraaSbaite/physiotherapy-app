int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
int? _intOrNull(dynamic v) => v is num ? v.toInt() : null;

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : const [];

class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    this.description = '',
    this.category,
    this.videoUrl,
    this.imageUrls = const [],
    this.precautions,
    this.defaultSets,
    this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultRestSeconds,
  });

  final String id;
  final String title;
  final String description;
  final String? category;
  final String? videoUrl;
  final List<String> imageUrls;
  final String? precautions;
  final int? defaultSets;
  final int? defaultReps;
  final int? defaultDurationSeconds;
  final int? defaultRestSeconds;

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        category: j['category'] as String?,
        videoUrl: j['videoUrl'] as String?,
        imageUrls: _strings(j['imageUrls']),
        precautions: j['precautions'] as String?,
        defaultSets: _intOrNull(j['defaultSets']),
        defaultReps: _intOrNull(j['defaultReps']),
        defaultDurationSeconds: _intOrNull(j['defaultDurationSeconds']),
        defaultRestSeconds: _intOrNull(j['defaultRestSeconds']),
      );

  // Empty strings and null clear a field on the server (PATCH).
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category ?? '',
        'videoUrl': videoUrl ?? '',
        'imageUrls': imageUrls,
        'precautions': precautions ?? '',
        'defaultSets': defaultSets,
        'defaultReps': defaultReps,
        'defaultDurationSeconds': defaultDurationSeconds,
        'defaultRestSeconds': defaultRestSeconds,
      };
}

/// How an assignment repeats. Matches the backend's repeat.type.
enum RepeatType {
  auto('auto', 'Spread evenly'),
  daily('daily', 'Every day'),
  weekly('weekly', 'Selected days');

  const RepeatType(this.api, this.label);
  final String api;
  final String label;

  static RepeatType parse(String? v) =>
      values.firstWhere((t) => t.api == v, orElse: () => RepeatType.auto);
}

/// Backend weekdays are 0 = Sunday ... 6 = Saturday.
/// The app uses DateTime's 1 = Monday ... 7 = Sunday.
int weekdayToApi(int appDay) => appDay % 7;
int weekdayFromApi(int apiDay) => apiDay == 0 ? 7 : apiDay;

/// An exercise prescribed to a patient, linked to an appointment.
class ExerciseAssignment {
  const ExerciseAssignment({
    required this.id,
    required this.exercise,
    this.appointmentId,
    this.nextAppointmentId,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.restSeconds,
    this.instructions,
    this.repeatType = RepeatType.auto,
    this.daysOfWeek = const [],
    this.reminderTimes = const [],
    this.startDate,
    this.endDate,
    this.totalTimes = 1,
    this.doneCount = 0,
    this.completed = false,
  });

  final String id;
  final Exercise exercise;
  final String? appointmentId;
  final String? nextAppointmentId;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final int? restSeconds;
  final String? instructions;
  final RepeatType repeatType;

  /// 1 = Monday ... 7 = Sunday. Only used when [repeatType] is weekly.
  final List<int> daysOfWeek;

  /// "HH:MM" reminder times. Each one is a separate session each day.
  final List<String> reminderTimes;
  final DateTime? startDate;
  final DateTime? endDate;

  /// How many sessions the patient should do in total, and how many are done
  /// (the "6/10" progress).
  final int totalTimes;
  final int doneCount;

  /// Patient endpoints only: whether today's session(s) are done.
  final bool completed;

  double get progress => totalTimes == 0 ? 0 : (doneCount / totalTimes).clamp(0, 1).toDouble();

  factory ExerciseAssignment.fromJson(Map<String, dynamic> j) {
    final ex = j['exercise'];
    final repeat = j['repeat'] is Map ? j['repeat'] as Map : const {};
    final progress = j['progress'] is Map ? j['progress'] as Map : const {};
    return ExerciseAssignment(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      exercise: ex is Map<String, dynamic>
          ? Exercise.fromJson(ex)
          : Exercise(
              id: (j['exerciseId'] ?? '').toString(),
              title: (j['exerciseTitle'] ?? 'Exercise').toString()),
      appointmentId: j['appointmentId']?.toString(),
      nextAppointmentId: j['nextAppointmentId']?.toString(),
      sets: _intOrNull(j['sets']),
      reps: _intOrNull(j['reps']),
      durationSeconds: _intOrNull(j['durationSeconds']),
      restSeconds: _intOrNull(j['restSeconds']),
      instructions: j['instructions'] as String?,
      repeatType: RepeatType.parse(repeat['type'] as String?),
      daysOfWeek: (repeat['daysOfWeek'] as List?)
              ?.map((e) => weekdayFromApi(_int(e)))
              .toList() ??
          const [],
      reminderTimes: _strings(j['reminderTimes']),
      // Dates are plain "YYYY-MM-DD", parsed as local midnight.
      startDate: DateTime.tryParse((j['startDate'] ?? '').toString()),
      endDate: DateTime.tryParse((j['endDate'] ?? '').toString()),
      totalTimes: _int(j['totalTimes'], _int(progress['total'], 1)),
      doneCount: _int(progress['done']),
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
    this.sequenceNumber,
    this.painLevel,
    this.patientNote,
  });

  final String id;
  final String assignmentId;
  final String exerciseTitle;
  final DateTime completedAt;
  final int? sequenceNumber;

  /// Optional, 0 to 10.
  final int? painLevel;
  final String? patientNote;

  factory Completion.fromJson(Map<String, dynamic> j) => Completion(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        assignmentId: (j['assignmentId'] ?? '').toString(),
        exerciseTitle: (j['exerciseTitle'] ?? 'Exercise').toString(),
        completedAt:
            DateTime.tryParse((j['completedAt'] ?? '').toString())?.toLocal() ??
                DateTime.now(),
        sequenceNumber: _intOrNull(j['sequenceNumber']),
        painLevel: _intOrNull(j['painLevel']),
        patientNote: j['patientNote'] as String?,
      );
}
