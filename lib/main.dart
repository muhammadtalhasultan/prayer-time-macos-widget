import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/network/api_service.dart';
import 'features/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService().initApiService();
  final storage = await HydratedStorage.build(
    storageDirectory: await getApplicationSupportDirectory(),
  );
  HydratedBloc.storage = storage;
  runApp(const MyApp());
}
