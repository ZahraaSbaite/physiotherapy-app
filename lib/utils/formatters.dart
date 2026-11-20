String two(int n) => n.toString().padLeft(2, '0');

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String fmtTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// yyyy-MM-dd, used for API query parameters.
String isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// weekday: 1 = Monday ... 7 = Sunday (same as DateTime.weekday).
String weekdayShort(int weekday) => _weekdays[(weekday - 1) % 7];

String fmtDateLong(DateTime d) =>
    '${weekdayShort(d.weekday)}, ${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtSeconds(int s) {
  if (s < 60) return '$s s';
  final m = s ~/ 60;
  final r = s % 60;
  return r == 0 ? '$m min' : '$m min $r s';
}

String errorText(Object e) => e.toString().replaceFirst('Exception: ', '');
