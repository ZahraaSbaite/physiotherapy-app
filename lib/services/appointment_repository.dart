import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import 'api_guard.dart';
import 'providers.dart';

List<T> _list<T>(
  dynamic data,
  String key,
  T Function(Map<String, dynamic>) f,
) =>
    (unwrap(data, key) as List)
        .map((e) => f(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _one(dynamic data, String key) =>
    unwrap(data, key) as Map<String, dynamic>;

typedef AppointmentKey = ({String id, bool mine});

class AppointmentRepository {
  AppointmentRepository(this._dio);
  final Dio _dio;

  // ---- Admin ----
  Future<List<Appointment>> list({
    DateTime? from,
    DateTime? to,
    String? patientId,
  }) => guardApi(
    () async => _list(
      (await _dio.get(
        '/appointments',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          if (patientId != null) 'patientId': patientId,
        },
      )).data,
      'appointments',
      Appointment.fromJson,
    ),
  );

  Future<Appointment> get(String id) => guardApi(
    () async => Appointment.fromJson(
      _one((await _dio.get('/appointments/$id')).data, 'appointment'),
    ),
  );

  /// Standard create (single appointment).
  Future<Appointment> create(Appointment a) => guardApi(
    () async => Appointment.fromJson(
      _one(
        (await _dio.post('/appointments', data: a.toJson())).data,
        'appointment',
      ),
    ),
  );

  /// 👇 Create with recurrence payload (returns the first appointment;
  /// the backend returns an `appointments` array, but we only need one
  /// to confirm success).
  Future<List<Appointment>> createWithRecurrence(
    Map<String, dynamic> payload,
  ) => guardApi(
    () async => _list(
      (await _dio.post('/appointments', data: payload)).data,
      'appointments',
      Appointment.fromJson,
    ),
  );

  Future<Appointment> update(String id, Appointment a) => guardApi(
    () async => Appointment.fromJson(
      _one(
        (await _dio.patch(
          '/appointments/$id',
          data: a.toJson(),
        )).data,
        'appointment',
      ),
    ),
  );

  Future<void> patch(String id, Map<String, dynamic> fields) =>
      guardApi(() => _dio.patch('/appointments/$id', data: fields));

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete('/appointments/$id'));

  // ---- Patient ----
  Future<List<Appointment>> listMine({
    DateTime? from,
    DateTime? to,
  }) => guardApi(
    () async => _list(
      (await _dio.get(
        '/me/appointments',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      )).data,
      'appointments',
      Appointment.fromJson,
    ),
  );

  Future<Appointment> getMine(String id) => guardApi(
    () async => Appointment.fromJson(
      _one(
        (await _dio.get('/me/appointments/$id')).data,
        'appointment',
      ),
    ),
  );

  Future<Appointment> byKey(AppointmentKey key) =>
      key.mine ? getMine(key.id) : get(key.id);
}

// ---- Providers ----
final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepository(ref.watch(apiClientProvider).dio),
);

final appointmentProvider = FutureProvider.autoDispose.family<
  Appointment,
  AppointmentKey
>((ref, key) => ref.watch(appointmentRepositoryProvider).byKey(key));

/// Admin home "Today's schedule"
final appointmentsInRangeProvider = FutureProvider.autoDispose
    .family<List<Appointment>, ({DateTime from, DateTime to})>(
      (ref, range) => ref
          .watch(appointmentRepositoryProvider)
          .list(from: range.from, to: range.to),
    );

/// Patient home "Next appointment"
final myAppointmentsInRangeProvider = FutureProvider.autoDispose
    .family<List<Appointment>, ({DateTime from, DateTime to})>(
      (ref, range) => ref
          .watch(appointmentRepositoryProvider)
          .listMine(from: range.from, to: range.to),
    );

/// All appointments for a specific patient (used in AssignExerciseScreen)
final patientAppointmentsProvider = FutureProvider.autoDispose
    .family<List<Appointment>, String>(
      (ref, patientId) => ref
          .watch(appointmentRepositoryProvider)
          .list(patientId: patientId),
    );

/// All appointments for the logged-in patient (used in MyAppointmentsScreen)
final myAppointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>(
      (ref) => ref.watch(appointmentRepositoryProvider).listMine(),
    );
