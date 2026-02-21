import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/native/status_bar.dart';
import '../bloc/prayer_cubit.dart';
import 'settings_page.dart';

class Prayer {
  final String name;
  final TimeOfDay time;
  const Prayer(this.name, this.time);
}

class PrayerMenuPage extends StatefulWidget {
  const PrayerMenuPage({super.key});
  @override
  State<PrayerMenuPage> createState() => _PrayerMenuPageState();
}

class _PrayerMenuPageState extends State<PrayerMenuPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateStatusBar();
    });
    // update immediately
    _updateStatusBar();
  }

  void _updateStatusBar() {
    final label = _countdownLabel();
    StatusBar.setTitle(label);
  }

  List<Prayer> get prayers {
    final s = context.read<PrayerCubit>().state;
    final t = s.prayer?.data.timings;
    if (t == null) return const [];
    return [
      Prayer('Fajr', _parse(t.fajr)),
      Prayer('Dhuhr', _parse(t.dhuhr)),
      Prayer('Asr', _parse(t.asr)),
      Prayer('Maghrib', _parse(t.maghrib)),
      Prayer('Isha', _parse(t.isha)),
    ];
  }

  int get nextPrayerIndex {
    final now = TimeOfDay.fromDateTime(DateTime.now());
    for (int i = 0; i < prayers.length; i++) {
      if (_isAfter(now, prayers[i].time)) continue;
      return i;
    }
    return 0;
  }

  Future<void> _launchUrl(String url) async {
    final Uri url0 = Uri.parse(url);

    if (!await launchUrl(url0)) {
      throw Exception('Could not launch $url0');
    }
  }

  Duration get timeUntilNext {
    final now = DateTime.now();
    if (prayers.isEmpty) return const Duration();
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
    final twentyFourHour = context.read<PrayerCubit>().state.twentyFourHour;
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
    return BlocListener<PrayerCubit, PrayerState>(
      listenWhen: (prev, curr) =>
          prev.prayer != curr.prayer ||
          prev.twentyFourHour != curr.twentyFourHour,
      listener: (context, state) => _updateStatusBar(),
      child: BlocBuilder<PrayerCubit, PrayerState>(
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
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
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage('assets/logo.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sirate Mustaqeem',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                log('Fetching timings using current location');
                                context
                                    .read<PrayerCubit>()
                                    .fetchUsingCurrentLocation();
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              color: Colors.white70,
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
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            // _sectionHeader('Sirate Mustaqeem'),
                            // _locationChip(),
                            // const SizedBox(height: 8),
                            _sectionHeader('Prayer Timings'),
                            if (prayers.isEmpty)
                              _loadingTile()
                            else
                              ...prayers.map((p) => _prayerTile(p)),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
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
                            _actionTile(
                              title: 'About',
                              onTap: () async {
                                await _launchUrl(
                                  'https://github.com/muhammadtalhasultan/Sirat-E-Mustaqeem',
                                );
                              },
                            ),
                            _actionTile(
                              title: 'Quit',
                              onTap: () {
                                showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog.adaptive(
                                    title: const Text('Quit'),
                                    content: const Text(
                                      'Are you sure you want to quit?',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        isDefaultAction: true,
                                        child: const Text('No'),
                                      ),
                                      CupertinoDialogAction(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        isDestructiveAction: true,
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                ).then((confirmed) {
                                  if (confirmed == true) exit(0);
                                });
                              },
                            ),
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
      ),
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
          color: const Color(
            0xFF2A2B2E,
          ).withOpacity(Platform.isMacOS ? 0.35 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Builder(
              builder: (context) {
                final s = context.read<PrayerCubit>().state;
                final mode = s.automaticLocation ? 'Automatic' : 'Manual';
                final label = s.lat != null && s.lng != null
                    ? '$mode: ${s.lat!.toStringAsFixed(3)}, ${s.lng!.toStringAsFixed(3)}'
                    : mode;
                return Text(label, style: const TextStyle(color: Colors.white));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayerTile(Prayer p) {
    final isNext = prayers[nextPrayerIndex].name == p.name;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isNext
            ? const Color(0xFF11ad54)
            : const Color(0xFF232427).withOpacity(Platform.isMacOS ? 0.35 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (isNext)
            Container(
              width: 4,
              height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Expanded(
            child: Text(
              p.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            _formatTime(p.time),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      // borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(
            0xFF232427,
          ).withOpacity(Platform.isMacOS ? 0.35 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white)),
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
        color: const Color(0xFF232427).withOpacity(Platform.isMacOS ? 0.35 : 1),
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

TimeOfDay _parse(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  return TimeOfDay(hour: h, minute: m);
}
