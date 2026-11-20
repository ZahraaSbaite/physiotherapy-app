import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/admin_home_screen.dart';
import '../services/auth_controller.dart';
import '../screens/change_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/patient_home_screen.dart';
import '../widgets/nav_shell.dart';
import '../widgets/placeholders.dart';

// Patient management
import '../screens/patients_screen.dart';
import '../screens/patient_form_screen.dart';
import '../screens/patient_detail_screen.dart';
import '../screens/patient_progress_screen.dart';
// Exercises
import '../screens/exercises_screen.dart';
import '../screens/exercise_form_screen.dart';
import '../screens/assign_exercise_screen.dart';
import '../screens/my_exercises_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/exercise_history_screen.dart';
// Appointments
import '../screens/appointments_screen.dart';
import '../screens/appointment_form_screen.dart';
import '../screens/appointment_detail_screen.dart';
import '../screens/my_appointments_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const admin = '/admin';
  static const patient = '/patient';
}

const _adminItems = [
  NavItem(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
  NavItem(
    label: 'Patients',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  NavItem(
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  NavItem(
    label: 'Chat',
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
  ),
  NavItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

const _patientItems = [
  NavItem(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
  NavItem(
    label: 'Exercises',
    icon: Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center,
  ),
  NavItem(
    label: 'Appointments',
    icon: Icons.event_outlined,
    selectedIcon: Icons.event,
  ),
  NavItem(
    label: 'Chat',
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
  ),
  NavItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

final routerProvider = Provider<GoRouter>((ref) {
  // Tells the router to re-check its rules whenever the login state changes
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (previous, next) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.unknown:
          return location == AppRoutes.splash ? null : AppRoutes.splash;

        case AuthStatus.unauthenticated:
          return location == AppRoutes.login ? null : AppRoutes.login;

        case AuthStatus.authenticated:
          {
            final home =
                auth.user!.isAdmin ? AppRoutes.admin : AppRoutes.patient;
            // Each role may only stay inside its own area
            final inside = location == home || location.startsWith('$home/');
            return inside ? null : home;
          }
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ---------- Admin area ----------
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, shell) =>
                NavShell(navigationShell: shell, items: _adminItems),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.admin,
                builder: (context, state) => const AdminHomeScreen(),
              ),
            ],
          ),

          // Patients tab (also hosts the exercise library)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/patients',
                builder: (context, state) => const PatientsScreen(),
                routes: [
                  // 'new' must stay above ':id'
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PatientFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder:
                        (context, state) => PatientDetailScreen(
                          patientId: state.pathParameters['id']!,
                        ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder:
                            (context, state) => PatientFormScreen(
                              patientId: state.pathParameters['id'],
                            ),
                      ),
                      GoRoute(
                        path: 'progress',
                        builder:
                            (context, state) => PatientProgressScreen(
                              patientId: state.pathParameters['id']!,
                            ),
                      ),
                      GoRoute(
                        path: 'assign',
                        builder:
                            (context, state) => AssignExerciseScreen(
                              patientId: state.pathParameters['id']!,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/admin/exercises',
                builder: (context, state) => const ExercisesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ExerciseFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder:
                        (context, state) => ExerciseFormScreen(
                          exerciseId: state.pathParameters['id'],
                        ),
                  ),
                ],
              ),
            ],
          ),

          // Calendar tab (path changed from /admin/calendar to /admin/appointments)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/appointments',
                builder: (context, state) => const AppointmentsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder:
                        (context, state) => AppointmentFormScreen(
                          initialDate: DateTime.tryParse(
                            state.uri.queryParameters['date'] ?? '',
                          ),
                        ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder:
                        (context, state) => AppointmentDetailScreen(
                          appointmentId: state.pathParameters['id']!,
                        ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder:
                            (context, state) => AppointmentFormScreen(
                              appointmentId: state.pathParameters['id'],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/chat',
                builder:
                    (context, state) => const PlaceholderTab(
                      title: 'Chat',
                      icon: Icons.chat_bubble_outline,
                      message: 'Chats with your patients will appear here.',
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder:
                    (context, state) => const ProfileScreen(
                      changePasswordPath: '/admin/profile/change-password',
                      settingsPath: '/admin/profile/settings',
                    ),
                routes: [
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ---------- Patient area ----------
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, shell) =>
                NavShell(navigationShell: shell, items: _patientItems),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patient,
                builder: (context, state) => const PatientHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/exercises',
                builder: (context, state) => const MyExercisesScreen(),
                routes: [
                  // 'history' must stay above ':id'
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const ExerciseHistoryScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder:
                        (context, state) => ExerciseDetailScreen(
                          assignmentId: state.pathParameters['id']!,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/appointments',
                builder: (context, state) => const MyAppointmentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder:
                        (context, state) => AppointmentDetailScreen(
                          appointmentId: state.pathParameters['id']!,
                          readOnly: true,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/chat',
                builder:
                    (context, state) => const PlaceholderTab(
                      title: 'Chat',
                      icon: Icons.chat_bubble_outline,
                      message:
                          'Your chat with your therapist will appear here.',
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/profile',
                builder:
                    (context, state) => const ProfileScreen(
                      changePasswordPath: '/patient/profile/change-password',
                      settingsPath: '/patient/profile/settings',
                    ),
                routes: [
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
});
