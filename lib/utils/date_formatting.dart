const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatDayOfWeek(DateTime date) {
  final weekday = date.weekday;
  return _dayNames[weekday - 1];
}
