import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'core/network/api_service.dart';
import 'core/notifications/prayer_notification_service.dart';
import 'features/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone));
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
  }
  ApiService().initApiService();
  await PrayerNotificationService.instance.ensureInitialized();
  final storage = await HydratedStorage.build(
    storageDirectory: await getApplicationSupportDirectory(),
  );
  HydratedBloc.storage = storage;
  runApp(const MyApp());
}
