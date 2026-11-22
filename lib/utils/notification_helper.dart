import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart'; // for flutterLocalNotificationsPlugin
import '../models/appointment.dart';
import '../utils/formatters.dart';

/// Cancel any previously scheduled reminder for this appointment, then
/// schedule a new one if the appointment qualifies.
Future<void> scheduleAppointmentReminder(Appointment a) async {
  final plugin = flutterLocalNotificationsPlugin;

  // Cancel any existing notification for this appointment
  await plugin.cancel(a.id.hashCode);

  // Only schedule if:
  //  - reminder toggle is ON
  //  - appointment is scheduled (not cancelled/completed/no-show)
  //  - appointment is in the future
  if (!a.sendReminder) return;
  if (a.status != AppointmentStatus.scheduled) return;
  if (!a.start.isAfter(DateTime.now())) return;

  final reminderMinutes = a.reminderMinutesBefore ?? 60;
  final reminderTime = a.start.subtract(
    Duration(minutes: reminderMinutes),
  );

  // Don't schedule if the reminder time is already in the past
  if (!reminderTime.isAfter(DateTime.now())) return;

  final tzReminder = tz.TZDateTime.from(reminderTime, tz.local);

  await plugin.zonedSchedule(
    a.id.hashCode,
    'Upcoming Physiotherapy Session',
    'You have an appointment at ${fmtTime(a.start)}',
    tzReminder,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'appointment_reminders',
        'Appointment Reminders',
        channelDescription:
            'Reminders for upcoming physiotherapy appointments',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}

/// Schedule reminders for a list of appointments. Called whenever the
/// patient's appointment list is refreshed.
Future<void> scheduleAppointmentReminders(
  List<Appointment> appointments,
) async {
  for (final a in appointments) {
    await scheduleAppointmentReminder(a);
  }
}

/// Cancel all reminders (useful on logout).
Future<void> cancelAllAppointmentReminders() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}
