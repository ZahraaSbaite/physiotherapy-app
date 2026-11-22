import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient.dart';
import 'providers.dart'; // expected to expose apiClientProvider

/// All patient-related API calls. UI never touches Dio directly.
class PatientRepository {
  PatientRepository(this._dio);
  final Dio _dio;

  Future<List<Patient>> list() => _guard(() async {
        final res = await _dio.get('/patients');
        final data = res.data is Map ? res.data['patients'] ?? res.data['data'] : res.data;
        return (data as List)
            .map((e) => Patient.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Patient> get(String id) => _guard(() async {
        final res = await _dio.get('/patients/$id');
        final data = res.data is Map && res.data['patient'] != null
            ? res.data['patient']
            : res.data;
        return Patient.fromJson(data as Map<String, dynamic>);
      });

  Future<Patient> create(Patient patient, {required String password}) =>
      _guard(() async {
        final res = await _dio.post('/patients',
            data: {...patient.toJson(), 'password': password});
        final data = res.data is Map && res.data['patient'] != null
            ? res.data['patient']
            : res.data;
        return Patient.fromJson(data as Map<String, dynamic>);
      });

  Future<void> update(String id, Patient patient) =>
      _guard(() => _dio.patch('/patients/$id', data: patient.toJson()));

  Future<void> setActive(String id, bool active) => _guard(
      () => _dio.patch('/patients/$id/${active ? 'reactivate' : 'deactivate'}'));

  Future<void> resetPassword(String id, String newPassword) => _guard(() =>
      _dio.post('/patients/$id/reset-password',
          data: {'newPassword': newPassword}));

  /// Converts Dio failures into a readable message.
  /// Swap for the project's ApiException if it exposes a Dio factory.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Something went wrong. Check your connection and try again.';
      throw Exception(msg);
    }
  }
}

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => PatientRepository(ref.watch(apiClientProvider).dio),
);

final patientsProvider = FutureProvider.autoDispose<List<Patient>>(
  (ref) => ref.watch(patientRepositoryProvider).list(),
);

final patientProvider =
    FutureProvider.autoDispose.family<Patient, String>(
  (ref, id) => ref.watch(patientRepositoryProvider).get(id),
);
