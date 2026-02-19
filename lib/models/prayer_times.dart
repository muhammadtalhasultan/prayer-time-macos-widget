class PrayerTimes {
  final Map<String, String> timings;
  PrayerTimes(this.timings);
  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> t = json['data']['timings'] as Map<String, dynamic>;
    final filtered = <String, String>{
      'Fajr': _clean(t['Fajr']),
      'Dhuhr': _clean(t['Dhuhr']),
      'Asr': _clean(t['Asr']),
      'Maghrib': _clean(t['Maghrib']),
      'Isha': _clean(t['Isha']),
    };
    return PrayerTimes(filtered);
  }

  static String _clean(dynamic v) {
    final s = v?.toString() ?? '';
    final i = s.indexOf('(');
    if (i >= 0) return s.substring(0, i).trim();
    return s.trim();
  }
}
