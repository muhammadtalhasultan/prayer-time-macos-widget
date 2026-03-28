import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/prayer_notification_service.dart';
import '../bloc/prayer_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  bool _isSavingLocation = false;

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

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
                  child: BlocConsumer<PrayerCubit, PrayerState>(
                    listener: (context, state) {
                      if (!_isSavingLocation) return;
                      if (state.status == LoadStatus.success) {
                        setState(() => _isSavingLocation = false);
                        Navigator.of(context).pop();
                        return;
                      }
                      if (state.status == LoadStatus.error) {
                        setState(() => _isSavingLocation = false);
                      }
                    },
                    builder: (context, state) {
                      if (_cityController.text.isEmpty) {
                        _cityController.text = state.city;
                      }
                      if (_countryController.text.isEmpty) {
                        _countryController.text = state.country;
                      }
                      return ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _settingsSection('Prayer times', [
                            _rowLabel(
                              'Method',
                              trailing: _dropdown(
                                ['Karachi', 'MWL', 'ISNA', 'Umm Al-Qura'],
                                state.method,
                                (v) => context.read<PrayerCubit>().setMethod(v),
                              ),
                            ),
                            _rowLabel(
                              'Madhhab',
                              trailing: _segmented(
                                const ['Shafi', 'Hanafi'],
                                state.useHanafi ? 'Hanafi' : 'Shafi',
                                (v) => context.read<PrayerCubit>().setUseHanafi(
                                      v == 'Hanafi',
                                    ),
                              ),
                            ),
                          ]),
                          _settingsSection('Time', [
                            _switchRow(
                              '24-Hour Time',
                              state.twentyFourHour,
                              (v) => context.read<PrayerCubit>().setTwentyFourHour(
                                    v,
                                  ),
                            ),
                          ]),
                          _settingsSection('Notifications', [
                            _switchRow(
                              'Prayer notifications',
                              state.prayerNotificationsEnabled,
                              (v) async {
                                await context
                                    .read<PrayerCubit>()
                                    .setPrayerNotifications(v);
                              },
                            ),
                            if (kDebugMode)
                              _buttonRow(
                                'Test Notification (5 sec)',
                                () async {
                                  await PrayerNotificationService.instance
                                      .sendTestNotification();
                                },
                              ),
                          ]),
                          _settingsSection('Location', [
                            _textInputRow(
                              'City',
                              controller: _cityController,
                              hint: 'e.g. Lahore',
                            ),
                            _textInputRow(
                              'Country',
                              controller: _countryController,
                              hint: 'e.g. Pakistan',
                            ),
                            _buttonRow(
                              _isSavingLocation
                                  ? 'Saving...'
                                  : 'Save city & refresh',
                              _saveCitySettings,
                              isLoading: _isSavingLocation,
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

  Widget _buttonRow(
    String text,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: isLoading ? null : onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF2A2B2E),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCitySettings() async {
    if (_isSavingLocation) return;
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();
    if (city.isEmpty || country.isEmpty) return;

    setState(() => _isSavingLocation = true);
    await context.read<PrayerCubit>().setLocation(city: city, country: country);
  }

  Widget _textInputRow(
    String label, {
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF2A2B2E),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
