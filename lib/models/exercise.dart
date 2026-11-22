int _int(dynamic v, [int fallback = 0]) =>
    v is num ? v.toInt() : fallback;
int? _intOrNull(dynamic v) => v is num ? v.toInt() : null;

List<String> _strings(dynamic v) =>
    v is List
        ? v
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : const [];

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

enum RepeatType {
  auto('auto', 'Spread evenly'),
  daily('daily', 'Every day'),
  weekly('weekly', 'Selected days');

  const RepeatType(this.api, this.label);
  final String api;
  final String label;

  static RepeatType parse(String? v) => values.firstWhere(
    (t) => t.api == v,
    orElse: () => RepeatType.auto,
  );
}

int weekdayToApi(int appDay) => appDay % 7;
int weekdayFromApi(int apiDay) => apiDay == 0 ? 7 : apiDay;

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
    this.isActive = true, // 👈 ADDED
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
  final List<int> daysOfWeek;
  final List<String> reminderTimes;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalTimes;
  final int doneCount;
  final bool completed;
  final bool
  isActive; // 👈 ADDED: false when the exercise was "stopped" (history kept)

  double get progress =>
      totalTimes == 0
          ? 0
          : (doneCount / totalTimes).clamp(0, 1).toDouble();

  factory ExerciseAssignment.fromJson(Map<String, dynamic> j) {
    final ex = j['exercise'];
    final repeat = j['repeat'] is Map ? j['repeat'] as Map : const {};
    final progress =
        j['progress'] is Map ? j['progress'] as Map : const {};
    return ExerciseAssignment(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      exercise:
          ex is Map<String, dynamic>
              ? Exercise.fromJson(ex)
              : Exercise(
                id: (j['exerciseId'] ?? '').toString(),
                title: (j['exerciseTitle'] ?? 'Exercise').toString(),
              ),
      appointmentId: j['appointmentId']?.toString(),
      nextAppointmentId: j['nextAppointmentId']?.toString(),
      sets: _intOrNull(j['sets']),
      reps: _intOrNull(j['reps']),
      durationSeconds: _intOrNull(j['durationSeconds']),
      restSeconds: _intOrNull(j['restSeconds']),
      instructions: j['instructions'] as String?,
      repeatType: RepeatType.parse(repeat['type'] as String?),
      daysOfWeek:
          (repeat['daysOfWeek'] as List?)
              ?.map((e) => weekdayFromApi(_int(e)))
              .toList() ??
          const [],
      reminderTimes: _strings(j['reminderTimes']),
      startDate: DateTime.tryParse((j['startDate'] ?? '').toString()),
      endDate: DateTime.tryParse((j['endDate'] ?? '').toString()),
      totalTimes: _int(j['totalTimes'], _int(progress['total'], 1)),
      doneCount: _int(progress['done']),
      completed: j['completed'] as bool? ?? false,
      isActive: j['isActive'] as bool? ?? true, // 👈 ADDED
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
    this.scheduledTime,
  });

  final String id;
  final String assignmentId;
  final String exerciseTitle;
  final DateTime completedAt;
  final int? sequenceNumber;
  final int? painLevel;
  final String? patientNote;
  final String? scheduledTime;

  factory Completion.fromJson(Map<String, dynamic> j) => Completion(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    assignmentId: (j['assignmentId'] ?? '').toString(),
    exerciseTitle: (j['exerciseTitle'] ?? 'Exercise').toString(),
    completedAt:
        DateTime.tryParse(
          (j['completedAt'] ?? '').toString(),
        )?.toLocal() ??
        DateTime.now(),
    sequenceNumber: _intOrNull(j['sequenceNumber']),
    painLevel: _intOrNull(j['painLevel']),
    patientNote: j['patientNote'] as String?,
    scheduledTime: j['scheduledTime'] as String?,
  );
}

class UnreadNote {
  const UnreadNote({
    required this.id,
    required this.patientName,
    required this.exerciseTitle,
    required this.patientNote,
    this.painLevel,
    required this.completedAt,
  });

  final String id;
  final String patientName;
  final String exerciseTitle;
  final String patientNote;
  final int? painLevel;
  final DateTime completedAt;

  factory UnreadNote.fromJson(Map<String, dynamic> j) => UnreadNote(
    id: j['id'].toString(),
    patientName: j['patientName'].toString(),
    exerciseTitle: j['exerciseTitle'].toString(),
    patientNote: j['patientNote'].toString(),
    painLevel: j['painLevel'] as int?,
    completedAt:
        DateTime.parse(j['completedAt'].toString()).toLocal(),
  );
}
