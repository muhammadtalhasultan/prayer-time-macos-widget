class PrayerTimes {
  final int code;
  final String status;
  final Data data;
  PrayerTimes({required this.code, required this.status, required this.data});
  factory PrayerTimes.fromJson(Map<String, dynamic> json) => PrayerTimes(
    code: json['code'] as int,
    status: json['status'] as String,
    data: Data.fromJson(json['data'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'code': code,
    'status': status,
    'data': data.toJson(),
  };
}

class Data {
  final Timings timings;
  final Date date;
  final Meta meta;
  Data({required this.timings, required this.date, required this.meta});
  factory Data.fromJson(Map<String, dynamic> json) => Data(
    timings: Timings.fromJson(json['timings'] as Map<String, dynamic>),
    date: Date.fromJson(json['date'] as Map<String, dynamic>),
    meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'timings': timings.toJson(),
    'date': date.toJson(),
    'meta': meta.toJson(),
  };
}

class Date {
  final String readable;
  final String timestamp;
  final Hijri hijri;
  final Gregorian gregorian;
  Date({
    required this.readable,
    required this.timestamp,
    required this.hijri,
    required this.gregorian,
  });
  factory Date.fromJson(Map<String, dynamic> json) => Date(
    readable: json['readable'] as String,
    timestamp: json['timestamp']?.toString() ?? '',
    hijri: Hijri.fromJson(json['hijri'] as Map<String, dynamic>),
    gregorian: Gregorian.fromJson(json['gregorian'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'readable': readable,
    'timestamp': timestamp,
    'hijri': hijri.toJson(),
    'gregorian': gregorian.toJson(),
  };
}

class Gregorian {
  final String date;
  final String format;
  final String day;
  final GregorianWeekday weekday;
  final GregorianMonth month;
  final String year;
  final Designation designation;
  final bool? lunarSighting;
  Gregorian({
    required this.date,
    required this.format,
    required this.day,
    required this.weekday,
    required this.month,
    required this.year,
    required this.designation,
    this.lunarSighting,
  });
  factory Gregorian.fromJson(Map<String, dynamic> json) => Gregorian(
    date: json['date'] as String,
    format: json['format'] as String,
    day: json['day']?.toString() ?? '',
    weekday: GregorianWeekday.fromJson(json['weekday'] as Map<String, dynamic>),
    month: GregorianMonth.fromJson(json['month'] as Map<String, dynamic>),
    year: json['year']?.toString() ?? '',
    designation: Designation.fromJson(
      json['designation'] as Map<String, dynamic>,
    ),
    lunarSighting: json['lunarSighting'] as bool?,
  );
  Map<String, dynamic> toJson() => {
    'date': date,
    'format': format,
    'day': day,
    'weekday': weekday.toJson(),
    'month': month.toJson(),
    'year': year,
    'designation': designation.toJson(),
    'lunarSighting': lunarSighting,
  };
}

class Designation {
  final String abbreviated;
  final String expanded;
  Designation({required this.abbreviated, required this.expanded});
  factory Designation.fromJson(Map<String, dynamic> json) => Designation(
    abbreviated: json['abbreviated'] as String,
    expanded: json['expanded'] as String,
  );
  Map<String, dynamic> toJson() => {
    'abbreviated': abbreviated,
    'expanded': expanded,
  };
}

class GregorianMonth {
  final int number;
  final String en;
  GregorianMonth({required this.number, required this.en});
  factory GregorianMonth.fromJson(Map<String, dynamic> json) => GregorianMonth(
    number: (json['number'] as num).toInt(),
    en: json['en'] as String,
  );
  Map<String, dynamic> toJson() => {'number': number, 'en': en};
}

class GregorianWeekday {
  final String en;
  GregorianWeekday({required this.en});
  factory GregorianWeekday.fromJson(Map<String, dynamic> json) =>
      GregorianWeekday(en: json['en'] as String);
  Map<String, dynamic> toJson() => {'en': en};
}

class Hijri {
  final String date;
  final String format;
  final String day;
  final HijriWeekday weekday;
  final HijriMonth month;
  final String year;
  final Designation designation;
  final List<dynamic> holidays;
  final List<dynamic>? adjustedHolidays;
  final String? method;
  Hijri({
    required this.date,
    required this.format,
    required this.day,
    required this.weekday,
    required this.month,
    required this.year,
    required this.designation,
    required this.holidays,
    this.adjustedHolidays,
    this.method,
  });
  factory Hijri.fromJson(Map<String, dynamic> json) => Hijri(
    date: json['date'] as String,
    format: json['format'] as String,
    day: json['day']?.toString() ?? '',
    weekday: HijriWeekday.fromJson(json['weekday'] as Map<String, dynamic>),
    month: HijriMonth.fromJson(json['month'] as Map<String, dynamic>),
    year: json['year']?.toString() ?? '',
    designation: Designation.fromJson(
      json['designation'] as Map<String, dynamic>,
    ),
    holidays: (json['holidays'] as List?) ?? const [],
    adjustedHolidays: json['adjustedHolidays'] as List?,
    method: json['method'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'date': date,
    'format': format,
    'day': day,
    'weekday': weekday.toJson(),
    'month': month.toJson(),
    'year': year,
    'designation': designation.toJson(),
    'holidays': holidays,
    'adjustedHolidays': adjustedHolidays,
    'method': method,
  };
}

class HijriMonth {
  final int number;
  final String en;
  final String ar;
  final int? days;
  HijriMonth({
    required this.number,
    required this.en,
    required this.ar,
    this.days,
  });
  factory HijriMonth.fromJson(Map<String, dynamic> json) => HijriMonth(
    number: (json['number'] as num).toInt(),
    en: json['en'] as String,
    ar: json['ar'] as String,
    days: (json['days'] as num?)?.toInt(),
  );
  Map<String, dynamic> toJson() => {
    'number': number,
    'en': en,
    'ar': ar,
    'days': days,
  };
}

class HijriWeekday {
  final String en;
  final String ar;
  HijriWeekday({required this.en, required this.ar});
  factory HijriWeekday.fromJson(Map<String, dynamic> json) =>
      HijriWeekday(en: json['en'] as String, ar: json['ar'] as String);
  Map<String, dynamic> toJson() => {'en': en, 'ar': ar};
}

class Meta {
  final double latitude;
  final double longitude;
  final String timezone;
  final Method method;
  final String latitudeAdjustmentMethod;
  final String midnightMode;
  final String school;
  final Map<String, int> offset;
  Meta({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.method,
    required this.latitudeAdjustmentMethod,
    required this.midnightMode,
    required this.school,
    required this.offset,
  });
  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timezone: json['timezone'] as String,
    method: Method.fromJson(json['method'] as Map<String, dynamic>),
    latitudeAdjustmentMethod: json['latitudeAdjustmentMethod'] as String,
    midnightMode: json['midnightMode'] as String,
    school: json['school'] as String,
    offset: Map<String, int>.from(
      (json['offset'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
    ),
  );
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'method': method.toJson(),
    'latitudeAdjustmentMethod': latitudeAdjustmentMethod,
    'midnightMode': midnightMode,
    'school': school,
    'offset': offset,
  };
}

class Method {
  final int id;
  final String name;
  final Params params;
  final Location location;
  Method({
    required this.id,
    required this.name,
    required this.params,
    required this.location,
  });
  factory Method.fromJson(Map<String, dynamic> json) => Method(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    params: Params.fromJson(json['params'] as Map<String, dynamic>),
    location: Location.fromJson(json['location'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'params': params.toJson(),
    'location': location.toJson(),
  };
}

class Location {
  final double latitude;
  final double longitude;
  Location({required this.latitude, required this.longitude});
  factory Location.fromJson(Map<String, dynamic> json) => Location(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class Params {
  final int fajr;
  final int isha;
  Params({required this.fajr, required this.isha});
  factory Params.fromJson(Map<String, dynamic> json) => Params(
    fajr: (json['Fajr'] ?? json['fajr'] as int),
    isha: (json['Isha'] ?? json['isha'] as int),
  );
  Map<String, dynamic> toJson() => {'Fajr': fajr, 'Isha': isha};
}

class Timings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String sunset;
  final String maghrib;
  final String isha;
  final String imsak;
  final String midnight;
  final String firstthird;
  final String lastthird;
  Timings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.midnight,
    required this.firstthird,
    required this.lastthird,
  });
  factory Timings.fromJson(Map<String, dynamic> json) => Timings(
    fajr: _clean(json['Fajr'] ?? json['fajr']),
    sunrise: _clean(json['Sunrise'] ?? json['sunrise']),
    dhuhr: _clean(json['Dhuhr'] ?? json['dhuhr']),
    asr: _clean(json['Asr'] ?? json['asr']),
    sunset: _clean(json['Sunset'] ?? json['sunset']),
    maghrib: _clean(json['Maghrib'] ?? json['maghrib']),
    isha: _clean(json['Isha'] ?? json['isha']),
    imsak: _clean(json['Imsak'] ?? json['imsak']),
    midnight: _clean(json['Midnight'] ?? json['midnight']),
    firstthird: _clean(json['Firstthird'] ?? json['firstthird']),
    lastthird: _clean(json['Lastthird'] ?? json['lastthird']),
  );
  Map<String, dynamic> toJson() => {
    'Fajr': fajr,
    'Sunrise': sunrise,
    'Dhuhr': dhuhr,
    'Asr': asr,
    'Sunset': sunset,
    'Maghrib': maghrib,
    'Isha': isha,
    'Imsak': imsak,
    'Midnight': midnight,
    'Firstthird': firstthird,
    'Lastthird': lastthird,
  };
  static String _clean(dynamic v) {
    final s = v?.toString() ?? '';
    final i = s.indexOf('(');
    if (i >= 0) return s.substring(0, i).trim();
    final j = s.indexOf(' ');
    if (j >= 0) return s.substring(0, j).trim();
    return s.trim();
  }
}
