import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/prayer_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String menuBarStyle = 'Next';
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
                            _rowLabel(
                              'Menu Bar Style',
                              trailing: _segmented(
                                ['Next', 'Icon'],
                                menuBarStyle,
                                (v) {
                                  setState(() => menuBarStyle = v);
                                },
                              ),
                            ),
                            _switchRow(
                              'Compact Main View',
                              compactMainView,
                              (v) => setState(() => compactMainView = v),
                            ),
                            _switchRow('24-Hour Time', state.twentyFourHour, (
                              v,
                            ) {
                              context.read<PrayerCubit>().setTwentyFourHour(v);
                            }),
                            _switchRow(
                              'Use Accent Color',
                              useAccentColor,
                              (v) => setState(() => useAccentColor = v),
                            ),
                            _switchRow(
                              'Show Sunnah Prayers',
                              showSunnah,
                              (v) => setState(() => showSunnah = v),
                            ),
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
                            _switchRow(
                              'Hanafi Madhhab',
                              hanafi,
                              (v) => setState(() => hanafi = v),
                            ),
                          ]),
                          _settingsSection('Location', [
                            _switchRow('Automatic', automaticLocation ?? true, (
                              v,
                            ) {
                              setState(() => automaticLocation = v);
                              context.read<PrayerCubit>().setAutomaticLocation(
                                v,
                              );
                            }),
                            _buttonRow('Refresh Location & Timings', () {
                              context
                                  .read<PrayerCubit>()
                                  .fetchUsingCurrentLocation();
                            }),
                          ]),
                          _settingsSection('System', [
                            _switchRow(
                              'Run at Login',
                              runAtLogin,
                              (v) => setState(() => runAtLogin = v),
                            ),
                            _switchRow(
                              'Prayer Notifications',
                              prayerNotifications,
                              (v) => setState(() => prayerNotifications = v),
                            ),
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
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          ?trailing,
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
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return SizedBox(
      height: 30,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
    List<String> items,
    String value,
    ValueChanged<String> onChanged,
  ) {
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
