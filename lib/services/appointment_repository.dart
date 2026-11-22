import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import 'api_guard.dart';
import 'providers.dart'; // expected to expose apiClientProvider

List<Appointment> _list(dynamic data) => (unwrap(data, 'appointments') as List)
    .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
    .toList();

Appointment _one(dynamic data) =>
    Appointment.fromJson(unwrap(data, 'appointment') as Map<String, dynamic>);

class AppointmentRepository {
  AppointmentRepository(this._dio);
  final Dio _dio;

  // ---- Therapist ----
  Future<List<Appointment>> inRange(DateTime from, DateTime to) =>
      guardApi(() async => _list((await _dio.get('/appointments',
              queryParameters: {
                'from': from.toUtc().toIso8601String(),
                'to': to.toUtc().toIso8601String(),
              }))
          .data));

  Future<Appointment> get(String id, {required bool mine}) => guardApi(
      () async => _one((await _dio.get(mine ? '/me/appointments/$id' : '/appointments/$id')).data));

  Future<void> create(Appointment a) =>
      guardApi(() => _dio.post('/appointments', data: a.toJson()));

  Future<void> update(String id, Appointment a) =>
      guardApi(() => _dio.patch('/appointments/$id', data: a.toJson()));

  /// Partial update, e.g. {'status': 'completed'} or {'payment': {'status': 'paid'}}.
  Future<void> patch(String id, Map<String, dynamic> fields) =>
      guardApi(() => _dio.patch('/appointments/$id', data: fields));

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete('/appointments/$id'));

  /// All appointments of one patient (used to link exercises to an appointment).
  Future<List<Appointment>> forPatient(String patientId) => guardApi(() async =>
      _list((await _dio.get('/appointments',
              queryParameters: {'patientId': patientId}))
          .data));

  // ---- Patient ----
  Future<List<Appointment>> mine() =>
      guardApi(() async => _list((await _dio.get('/me/appointments')).data));
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
    (ref) => AppointmentRepository(ref.watch(apiClientProvider).dio));

final appointmentsProvider = FutureProvider.autoDispose
    .family<List<Appointment>, DateTimeRange>((ref, range) => ref
        .watch(appointmentRepositoryProvider)
        .inRange(range.start, range.end));

typedef AppointmentKey = ({String id, bool mine});

final appointmentProvider = FutureProvider.autoDispose
    .family<Appointment, AppointmentKey>((ref, key) => ref
        .watch(appointmentRepositoryProvider)
        .get(key.id, mine: key.mine));

final patientAppointmentsProvider = FutureProvider.autoDispose
    .family<List<Appointment>, String>((ref, patientId) =>
        ref.watch(appointmentRepositoryProvider).forPatient(patientId));

final myAppointmentsProvider = FutureProvider.autoDispose<List<Appointment>>(
    (ref) => ref.watch(appointmentRepositoryProvider).mine());
