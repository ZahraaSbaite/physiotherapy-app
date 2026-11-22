import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise.dart';
import '../utils/formatters.dart';
import 'api_guard.dart';
import 'providers.dart'; // expected to expose apiClientProvider

List<T> _list<T>(dynamic data, String key, T Function(Map<String, dynamic>) f) =>
    (unwrap(data, key) as List).map((e) => f(e as Map<String, dynamic>)).toList();

Map<String, dynamic> _one(dynamic data, String key) =>
    unwrap(data, key) as Map<String, dynamic>;

class ExerciseRepository {
  ExerciseRepository(this._dio);
  final Dio _dio;

  // ---- Therapist: exercise library ----
  Future<List<Exercise>> list() => guardApi(() async =>
      _list(( await _dio.get('/exercises')).data, 'exercises', Exercise.fromJson));

  Future<Exercise> get(String id) => guardApi(() async =>
      Exercise.fromJson(_one((await _dio.get('/exercises/$id')).data, 'exercise')));

  Future<void> create(Exercise e) =>
      guardApi(() => _dio.post('/exercises', data: e.toJson()));

  Future<void> update(String id, Exercise e) =>
      guardApi(() => _dio.patch('/exercises/$id', data: e.toJson()));

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete('/exercises/$id'));

  // ---- Therapist: assignments and progress ----
  Future<List<ExerciseAssignment>> patientAssignments(String patientId) =>
      guardApi(() async => _list(
          (await _dio.get('/patients/$patientId/assignments')).data,
          'assignments',
          ExerciseAssignment.fromJson));

  Future<void> assign(
    String patientId, {
    required String exerciseId,
    required String appointmentId,
    String? nextAppointmentId,
    int? sets,
    int? reps,
    int? durationSeconds,
    int? restSeconds,
    String? instructions,
    required DateTime startDate,
    required DateTime endDate,
    required int totalTimes,
    required RepeatType repeatType,
    List<int> daysOfWeek = const [],
    List<String> reminderTimes = const [],
  }) =>
      guardApi(() => _dio.post('/patients/$patientId/assignments', data: {
            'exerciseId': exerciseId,
            'appointmentId': appointmentId,
            if (nextAppointmentId != null) 'nextAppointmentId': nextAppointmentId,
            if (sets != null) 'sets': sets,
            if (reps != null) 'reps': reps,
            if (durationSeconds != null) 'durationSeconds': durationSeconds,
            if (restSeconds != null) 'restSeconds': restSeconds,
            if (instructions != null && instructions.isNotEmpty)
              'instructions': instructions,
            'startDate': isoDate(startDate),
            'endDate': isoDate(endDate),
            'totalTimes': totalTimes,
            'repeat': {
              'type': repeatType.api,
              // The app counts Monday = 1 ... Sunday = 7; the server Sunday = 0.
              'daysOfWeek': repeatType == RepeatType.weekly
                  ? (daysOfWeek.map(weekdayToApi).toList()..sort())
                  : <int>[],
            },
            'reminderTimes': reminderTimes,
          }));

  Future<void> removeAssignment(String assignmentId) =>
      guardApi(() => _dio.delete('/assignments/$assignmentId'));

  Future<List<Completion>> patientCompletions(String patientId) =>
      guardApi(() async => _list(
          (await _dio.get('/patients/$patientId/completions')).data,
          'completions',
          Completion.fromJson));

  // ---- Patient ----
  Future<List<ExerciseAssignment>> assignmentsForDay(DateTime day) =>
      guardApi(() async => _list(
          (await _dio.get('/me/assignments',
                  queryParameters: {'date': isoDate(day)}))
              .data,
          'assignments',
          ExerciseAssignment.fromJson));

  Future<ExerciseAssignment> myAssignment(String id) => guardApi(() async =>
      ExerciseAssignment.fromJson(
          _one((await _dio.get('/me/assignments/$id')).data, 'assignment')));

  /// Pain level is optional (0 to 10). The note is optional too.
  Future<void> complete(String assignmentId, {int? painLevel, String? patientNote}) =>
      guardApi(() => _dio.post('/me/assignments/$assignmentId/complete', data: {
            if (painLevel != null) 'painLevel': painLevel,
            if (patientNote != null && patientNote.isNotEmpty)
              'patientNote': patientNote,
            'date': isoDate(DateTime.now()),
          }));

  Future<List<Completion>> myCompletions() => guardApi(() async => _list(
      (await _dio.get('/me/completions')).data, 'completions', Completion.fromJson));
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
    (ref) => ExerciseRepository(ref.watch(apiClientProvider).dio));

final exercisesProvider = FutureProvider.autoDispose<List<Exercise>>(
    (ref) => ref.watch(exerciseRepositoryProvider).list());

final exerciseProvider = FutureProvider.autoDispose.family<Exercise, String>(
    (ref, id) => ref.watch(exerciseRepositoryProvider).get(id));

final patientAssignmentsProvider = FutureProvider.autoDispose
    .family<List<ExerciseAssignment>, String>((ref, patientId) =>
        ref.watch(exerciseRepositoryProvider).patientAssignments(patientId));

final patientCompletionsProvider = FutureProvider.autoDispose
    .family<List<Completion>, String>((ref, patientId) =>
        ref.watch(exerciseRepositoryProvider).patientCompletions(patientId));

final todayAssignmentsProvider =
    FutureProvider.autoDispose<List<ExerciseAssignment>>((ref) => ref
        .watch(exerciseRepositoryProvider)
        .assignmentsForDay(DateTime.now()));

final myAssignmentProvider = FutureProvider.autoDispose
    .family<ExerciseAssignment, String>(
        (ref, id) => ref.watch(exerciseRepositoryProvider).myAssignment(id));

final myCompletionsProvider = FutureProvider.autoDispose<List<Completion>>(
    (ref) => ref.watch(exerciseRepositoryProvider).myCompletions());
