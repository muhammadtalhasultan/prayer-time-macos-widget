import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart' as hb;

import 'package:prayertime/main.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('hydrated_test');
    final storage = await hb.HydratedStorage.build(storageDirectory: dir);
    HydratedBloc.storage = storage;
  });
  testWidgets('Prayer menu renders and navigates to settings',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('24-Hour Time'), findsOneWidget);
  });
}
