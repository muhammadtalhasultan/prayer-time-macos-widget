import 'dart:convert';
import 'package:http/http.dart' as http;

class PrayerApi {
  static Future<Map<String, dynamic>> timingsByCoordinates({
    required double latitude,
    required double longitude,
    String method = 'Karachi',
  }) async {
    final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings?latitude=$latitude&longitude=$longitude&method=$method');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed ${res.statusCode}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }
}
