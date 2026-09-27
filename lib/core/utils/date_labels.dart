const _monthsFr = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String formatDayMonth(DateTime value) =>
    '${value.day} ${_monthsFr[value.month - 1]}';

String formatTimeHm(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDayMonthTime(DateTime value) =>
    '${formatDayMonth(value)} · ${formatTimeHm(value)}';
