import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'prayertime/bloc/prayer_cubit.dart';
import 'prayertime/view/prayer_menu_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return BlocProvider(
      create: (_) => PrayerCubit()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sirate Mustaqeem',
        theme: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: const Color(0xFF8AA5FF),
            secondary: const Color(0xFF8AA5FF),
          ),
          scaffoldBackgroundColor: const Color(0xFF1E1F22),
          textTheme: base.textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          dividerColor: const Color(0xFF2A2B2E),
          listTileTheme: const ListTileThemeData(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            horizontalTitleGap: 0,
            minLeadingWidth: 0,
          ),
        ),
        home: const PrayerMenuPage(),
      ),
    );
  }
}
