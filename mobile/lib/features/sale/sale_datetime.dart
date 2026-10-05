String formatSaleDateTime(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

String formatSaleDateLabel(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year}';
}

String formatSaleTimeLabel(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}';
}

bool isFutureSaleDateTime(DateTime value, DateTime now) => value.isAfter(now);

DateTime saleDateTimeToSend({
  DateTime? chosen,
  required DateTime now,
}) =>
    chosen ?? now;

DateTime saleDateTimeWithPickedDate(DateTime shown, DateTime day) =>
    DateTime(day.year, day.month, day.day, shown.hour, shown.minute);

DateTime saleDateTimeWithPickedTime(DateTime shown, int hour, int minute) =>
    DateTime(shown.year, shown.month, shown.day, hour, minute);
