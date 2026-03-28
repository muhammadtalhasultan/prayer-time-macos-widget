import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../core/network/api_service.dart';
import '../../../core/notifications/prayer_notification_service.dart';
import '../models/prayer_times.dart';

enum LoadStatus { idle, loading, success, error }

class PrayerState {
  final PrayerTimes? prayer;
  final bool twentyFourHour;
  final String method;
  final bool useHanafi;
  final bool prayerNotificationsEnabled;
  final String city;
  final String country;
  final LoadStatus status;
  final String? error;
  final String? lastFetchKey;

  const PrayerState({
    required this.prayer,
    required this.twentyFourHour,
    required this.method,
    required this.useHanafi,
    required this.prayerNotificationsEnabled,
    required this.city,
    required this.country,
    required this.status,
    this.error,
    this.lastFetchKey,
  });

  factory PrayerState.initial() => const PrayerState(
    prayer: null,
    twentyFourHour: false,
    method: 'Karachi',
    useHanafi: false,
    prayerNotificationsEnabled: false,
    city: 'Lahore',
    country: 'Pakistan',
    status: LoadStatus.idle,
    lastFetchKey: null,
  );

  PrayerState copyWith({
    PrayerTimes? prayer,
    bool? twentyFourHour,
    String? method,
    bool? useHanafi,
    bool? prayerNotificationsEnabled,
    String? city,
    String? country,
    LoadStatus? status,
    String? error,
    String? lastFetchKey,
  }) {
    return PrayerState(
      prayer: prayer ?? this.prayer,
      twentyFourHour: twentyFourHour ?? this.twentyFourHour,
      method: method ?? this.method,
      useHanafi: useHanafi ?? this.useHanafi,
      prayerNotificationsEnabled:
          prayerNotificationsEnabled ?? this.prayerNotificationsEnabled,
      city: city ?? this.city,
      country: country ?? this.country,
      status: status ?? this.status,
      error: error,
      lastFetchKey: lastFetchKey ?? this.lastFetchKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'prayer': prayer?.toJson(),
    'twentyFourHour': twentyFourHour,
    'method': method,
    'useHanafi': useHanafi,
    'prayerNotificationsEnabled': prayerNotificationsEnabled,
    'city': city,
    'country': country,
    'lastFetchKey': lastFetchKey,
  };

  factory PrayerState.fromJson(Map<String, dynamic> json) {
    return PrayerState(
      prayer: json['prayer'] != null
          ? PrayerTimes.fromJson(
              (json['prayer'] as Map).cast<String, dynamic>(),
            )
          : null,
      twentyFourHour: json['twentyFourHour'] as bool? ?? false,
      method: json['method'] as String? ?? 'Karachi',
      useHanafi: json['useHanafi'] as bool? ?? false,
      prayerNotificationsEnabled:
          json['prayerNotificationsEnabled'] as bool? ?? false,
      city: json['city'] as String? ?? 'Lahore',
      country: json['country'] as String? ?? 'Pakistan',
      status: LoadStatus.idle,
      lastFetchKey: json['lastFetchKey'] as String?,
    );
  }
}

class PrayerCubit extends HydratedCubit<PrayerState> {
  PrayerCubit() : super(PrayerState.initial());

  Future<void> initialize() async {
    if (_hasTodayData()) {
      emit(state.copyWith(status: LoadStatus.success));
      await PrayerNotificationService.instance.sync(
        notificationsEnabled: state.prayerNotificationsEnabled,
        prayer: state.prayer,
      );
      return;
    }
    await fetchTimingsByCity(city: state.city, country: state.country);
  }

  Future<void> setTwentyFourHour(bool v) async {
    emit(state.copyWith(twentyFourHour: v));
  }

  Future<void> setMethod(String v) async {
    emit(state.copyWith(method: v));
    if (_hasTodayData()) return;
    await fetchTimingsByCity(city: state.city, country: state.country);
  }

  Future<void> setUseHanafi(bool v) async {
    if (v == state.useHanafi) return;
    emit(state.copyWith(useHanafi: v));
    await fetchTimingsByCity(city: state.city, country: state.country);
  }

  Future<void> setPrayerNotifications(bool enabled) async {
    if (enabled) {
      await PrayerNotificationService.instance.ensureInitialized();
      final granted =
          await PrayerNotificationService.instance.requestPermissions();
      if (!granted) {
        emit(
          state.copyWith(
            prayerNotificationsEnabled: false,
            error: 'Notification permission was denied',
          ),
        );
        await PrayerNotificationService.instance.sync(
          notificationsEnabled: false,
          prayer: state.prayer,
        );
        return;
      }
    }
    emit(
      state.copyWith(
        prayerNotificationsEnabled: enabled,
        error: null,
      ),
    );
    await PrayerNotificationService.instance.sync(
      notificationsEnabled: state.prayerNotificationsEnabled,
      prayer: state.prayer,
    );
  }

  Future<void> setLocation({required String city, required String country}) async {
    final normalizedCity = city.trim();
    final normalizedCountry = country.trim();
    if (normalizedCity.isEmpty || normalizedCountry.isEmpty) return;
    emit(state.copyWith(city: normalizedCity, country: normalizedCountry));
    await fetchTimingsByCity(city: normalizedCity, country: normalizedCountry);
  }

  Future<void> fetchTimingsByCity({
    required String city,
    required String country,
  }) async {
    try {
      final key = _buildKey(city, country, state.method, state.useHanafi);
      // if (state.lastFetchKey == key && state.prayer != null) {
      //   emit(state.copyWith(status: LoadStatus.success));
      //   return;
      // }
      emit(state.copyWith(status: LoadStatus.loading, error: null));
      final result = await ApiService().timingsByCity({
        'city': city,
        'country': country,
        'method': state.method,
        'school': state.useHanafi ? 1 : 0,
      });
      await result.fold(
        (failure) async {
          emit(
            state.copyWith(status: LoadStatus.error, error: failure.message),
          );
        },
        (response) async {
          final data = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : Map<String, dynamic>.from(response.data);
          final pt = PrayerTimes.fromJson(data);
          emit(
            state.copyWith(
              prayer: pt,
              status: LoadStatus.success,
              lastFetchKey: key,
            ),
          );
          await PrayerNotificationService.instance.sync(
            notificationsEnabled: state.prayerNotificationsEnabled,
            prayer: pt,
          );
        },
      );
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.error, error: e.toString()));
    }
  }

  bool _hasTodayData() {
    if (state.city.trim().isEmpty || state.country.trim().isEmpty) {
      return false;
    }
    final key =
        _buildKey(state.city, state.country, state.method, state.useHanafi);
    return state.lastFetchKey == key && state.prayer != null;
  }

  String _buildKey(
    String city,
    String country,
    String method,
    bool useHanafi,
  ) {
    final now = DateTime.now();
    final d =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '$method|${useHanafi ? 1 : 0}|${city.toLowerCase()}|${country.toLowerCase()}|$d';
  }

  @override
  PrayerState? fromJson(Map<String, dynamic> json) {
    try {
      return PrayerState.fromJson(json);
    } catch (_) {
      return PrayerState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(PrayerState state) {
    return state.toJson();
  }
}
