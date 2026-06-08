import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime dt, Locale locale) =>
    DateFormat.yMMMd(locale.toString()).format(dt.toLocal());

String formatDateTime(DateTime dt, Locale locale) {
  final local = dt.toLocal();
  final datePart = DateFormat.yMMMd(locale.toString()).format(local);
  final timePart = DateFormat.jm(locale.toString()).format(local);
  return '$datePart, $timePart';
}
