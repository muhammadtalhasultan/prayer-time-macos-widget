// import 'dart:ui' show FontFeature;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'bloc/prayer_cubit.dart';
import 'ui/prayer_menu_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HydratedStorage.build(
    storageDirectory: await getApplicationSupportDirectory(),
  );
  HydratedBloc.storage = storage;
  runApp(const MyApp());
}

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

class Prayer {
  final String name;
  final TimeOfDay time;
  const Prayer(this.name, this.time);
}

class PrayerMenu extends StatefulWidget {
  const PrayerMenu({super.key});
  @override
  State<PrayerMenu> createState() => _PrayerMenuState();
}

class _PrayerMenuState extends State<PrayerMenu> {
  List<Prayer> get prayers {
    final s = context.read<PrayerCubit>().state;
    final source = s.timings;
    final order = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return order
        .where((k) => source.containsKey(k))
        .map((k) => Prayer(k, _parse(source[k]!)))
        .toList();
  }

  int get nextPrayerIndex {
    final now = TimeOfDay.fromDateTime(DateTime.now());
    for (int i = 0; i < prayers.length; i++) {
      if (_isAfter(now, prayers[i].time)) continue;
      return i;
    }
    return 0;
  }

  Duration get timeUntilNext {
    final now = DateTime.now();
    final next = prayers[nextPrayerIndex].time;
    final nextDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      next.hour,
      next.minute,
    );
    final dt = nextDateTime.isAfter(now)
        ? nextDateTime
        : nextDateTime.add(const Duration(days: 1));
    return dt.difference(now);
  }

  static bool _isAfter(TimeOfDay a, TimeOfDay b) {
    if (a.hour != b.hour) return a.hour > b.hour;
    return a.minute > b.minute;
  }

  String _formatTime(TimeOfDay t) {
    final twentyFourHour =
        context.read<PrayerCubit>().state.twentyFourHour;
    if (twentyFourHour) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String _countdownLabel() {
    if (prayers.isEmpty) return 'Fetching timings…';
    final d = timeUntilNext;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${prayers[nextPrayerIndex].name} in ${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, state) {
        final label = _countdownLabel();
        return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints( maxHeight: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings, size: 18),
                        color: Colors.white70,
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _sectionHeader('Sirate Mustaqeem'),
                      _locationChip(),
                      const SizedBox(height: 8),
                      _sectionHeader('Fajr'),
                      if (prayers.isEmpty)
                        _loadingTile()
                      else
                        ...prayers.map((p) => _prayerTile(p)),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      _actionTile(
                        title: 'Settings',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      _actionTile(title: 'About', onTap: () {}),
                      _actionTile(title: 'Quit', onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _locationChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2B2E),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Builder(builder: (context) {
              final s = context.read<PrayerCubit>().state;
              final mode = s.automaticLocation ? 'Automatic' : 'Manual';
              final label = s.lat != null && s.lng != null
                  ? '$mode: ${s.lat!.toStringAsFixed(3)}, ${s.lng!.toStringAsFixed(3)}'
                  : '$mode';
              return Text(label, style: const TextStyle(color: Colors.white));
            }),
          ],
        ),
      ),
    );
  }

  Widget _prayerTile(Prayer p) {
    final isNext = prayers.indexOf(p) == nextPrayerIndex;
    final color = isNext ? const Color(0xFF8AA5FF) : Colors.white70;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFF26314F) : const Color(0xFF232427),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatTime(p.time),
            style: TextStyle(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF232427),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _loadingTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF232427),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Loading prayer times…',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String menuBarStyle = 'Countdown';
  bool compactMainView = false;
  bool useAccentColor = true;
  bool showSunnah = false;
  String? method;
  bool hanafi = false;
  bool? automaticLocation;
  bool runAtLogin = false;
  bool prayerNotifications = true;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Scaffold(
      backgroundColor: base.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: Colors.white70,
                      ),
                      const Expanded(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<PrayerCubit, PrayerState>(
                    builder: (context, state) {
                      method ??= state.method;
                      automaticLocation ??= state.automaticLocation;
                      return ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _settingsSection('Display', [
                            _rowLabel('Menu Bar Style', trailing: _segmented([
                              'Countdown',
                              'Next',
                              'Icon',
                            ], menuBarStyle, (v) {
                              setState(() => menuBarStyle = v);
                            })),
                            _switchRow('Compact Main View', compactMainView,
                                (v) => setState(() => compactMainView = v)),
                            _switchRow('24-Hour Time', state.twentyFourHour,
                                (v) {
                              context.read<PrayerCubit>().setTwentyFourHour(v);
                            }),
                            _switchRow('Use Accent Color', useAccentColor,
                                (v) => setState(() => useAccentColor = v)),
                            _switchRow('Show Sunnah Prayers', showSunnah,
                                (v) => setState(() => showSunnah = v)),
                          ]),
                          _settingsSection('Calculation', [
                            _rowLabel(
                              'Method',
                              trailing: _dropdown(
                                ['Karachi', 'MWL', 'ISNA', 'Umm Al-Qura'],
                                method ?? 'Karachi',
                                (v) {
                                  setState(() => method = v);
                                  context.read<PrayerCubit>().setMethod(v);
                                },
                              ),
                            ),
                            _switchRow('Hanafi Madhhab', hanafi,
                                (v) => setState(() => hanafi = v)),
                          ]),
                          _settingsSection('Location', [
                            _switchRow(
                              'Automatic',
                              automaticLocation ?? true,
                              (v) {
                                setState(() => automaticLocation = v);
                                context
                                    .read<PrayerCubit>()
                                    .setAutomaticLocation(v);
                              },
                            ),
                            _buttonRow('Change Manual Location', () {
                              context
                                  .read<PrayerCubit>()
                                  .setManualLocation(state.lat ?? 0, state.lng ?? 0);
                            }),
                          ]),
                          _settingsSection('System', [
                            _switchRow('Run at Login', runAtLogin,
                                (v) => setState(() => runAtLogin = v)),
                            _switchRow('Prayer Notifications', prayerNotifications,
                                (v) => setState(() => prayerNotifications = v)),
                          ]),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF232427),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _rowLabel(String label, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF8AA5FF),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
      List<String> items, String value, ValueChanged<String> onChanged) {
    return SizedBox(
      height: 30,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          dropdownColor: const Color(0xFF2A2B2E),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _segmented(
      List<String> items, String value, ValueChanged<String> onChanged) {
    return CupertinoSegmentedControl<String>(
      children: {
        for (final i in items)
          i: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(i),
          ),
      },
      groupValue: value,
      onValueChanged: onChanged,
      padding: const EdgeInsets.all(2),
    );
  }

  Widget _buttonRow(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF2A2B2E),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

TimeOfDay _parse(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  return TimeOfDay(hour: h, minute: m);
}
