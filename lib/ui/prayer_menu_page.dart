import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            constraints: const BoxConstraints(maxWidth: 340, maxHeight: 520),
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
                              log('Fetching timings using current location');
                              context.read<PrayerCubit>().fetchUsingCurrentLocation();
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
                          _sectionHeader('Sajda'),
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
            style: const TextStyle(
              color: Colors.white,
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

TimeOfDay _parse(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  return TimeOfDay(hour: h, minute: m);
}
