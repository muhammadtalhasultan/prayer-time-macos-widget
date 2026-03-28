import 'package:flutter/material.dart';

/// Parses Aladhan API time strings (e.g. "05:23", "05:23 (PKT)") to TimeOfDay.
TimeOfDay parseAladhanTimeToTimeOfDay(String hhmm) {
  // Handle formats like "05:23" or "05:23 (PKT)"
  final timePart = hhmm.split(' ')[0];
  final parts = timePart.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  return TimeOfDay(hour: h, minute: m);
}

/// Parses Aladhan API time strings to DateTime (today).
DateTime parseAladhanTimeToDateTime(String hhmm) {
  final time = parseAladhanTimeToTimeOfDay(hhmm);
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, time.hour, time.minute);
}
