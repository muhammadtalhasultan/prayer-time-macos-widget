import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../core/network/api_service.dart';
import '../models/prayer_times.dart';

enum LoadStatus { idle, loading, success, error }

class PrayerState {
  final PrayerTimes? prayer;
  final bool twentyFourHour;
  final String method;
  final bool automaticLocation;
  final double? lat;
  final double? lng;
  final LoadStatus status;
  final String? error;
  final String? lastFetchKey;

  const PrayerState({
    required this.prayer,
    required this.twentyFourHour,
    required this.method,
    required this.automaticLocation,
    required this.lat,
    required this.lng,
    required this.status,
    this.error,
    this.lastFetchKey,
  });

  factory PrayerState.initial() => const PrayerState(
    prayer: null,
    twentyFourHour: false,
    method: 'Karachi',
    automaticLocation: true,
    lat: null,
    lng: null,
    status: LoadStatus.idle,
    lastFetchKey: null,
  );

  PrayerState copyWith({
    PrayerTimes? prayer,
    bool? twentyFourHour,
    String? method,
    bool? automaticLocation,
    double? lat,
    double? lng,
    LoadStatus? status,
    String? error,
    String? lastFetchKey,
  }) {
    return PrayerState(
      prayer: prayer ?? this.prayer,
      twentyFourHour: twentyFourHour ?? this.twentyFourHour,
      method: method ?? this.method,
      automaticLocation: automaticLocation ?? this.automaticLocation,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      error: error,
      lastFetchKey: lastFetchKey ?? this.lastFetchKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'prayer': prayer?.toJson(),
    'twentyFourHour': twentyFourHour,
    'method': method,
    'automaticLocation': automaticLocation,
    'lat': lat,
    'lng': lng,
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
      automaticLocation: json['automaticLocation'] as bool? ?? true,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
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
      return;
    }
    if (state.automaticLocation) {
      await fetchUsingCurrentLocation();
    } else if (state.lat != null && state.lng != null) {
      await fetchTimings(lat: state.lat!, lng: state.lng!);
    }
  }

  Future<void> setTwentyFourHour(bool v) async {
    emit(state.copyWith(twentyFourHour: v));
  }

  Future<void> setMethod(String v) async {
    emit(state.copyWith(method: v));
    if (_hasTodayData()) return;
    if (state.lat != null && state.lng != null) {
      await fetchTimings(lat: state.lat!, lng: state.lng!);
    } else if (state.automaticLocation) {
      await fetchUsingCurrentLocation();
    }
  }

  Future<void> setAutomaticLocation(bool v) async {
    emit(state.copyWith(automaticLocation: v));
    if (v) {
      if (_hasTodayData()) return;
      await fetchUsingCurrentLocation();
    }
  }

  Future<void> setManualLocation(double lat, double lng) async {
    emit(state.copyWith(lat: lat, lng: lng, automaticLocation: false));
    await fetchTimings(lat: lat, lng: lng);
  }

  Future<void> fetchUsingCurrentLocation() async {
    try {
      emit(state.copyWith(status: LoadStatus.loading, error: null));
      final perm = await Geolocator.checkPermission();
      log('Permissions: $perm');
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        final r = await Geolocator.requestPermission();
        if (r == LocationPermission.denied ||
            r == LocationPermission.deniedForever) {
          emit(
            state.copyWith(
              status: LoadStatus.error,
              error: 'Location permission denied',
            ),
          );
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      emit(state.copyWith(lat: pos.latitude, lng: pos.longitude));
      await fetchTimings(lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.error, error: e.toString()));
    }
  }

  Future<void> fetchTimings({required double lat, required double lng}) async {
    try {
      final key = _buildKey(lat, lng, state.method);
      // if (state.lastFetchKey == key && state.prayer != null) {
      //   emit(state.copyWith(status: LoadStatus.success));
      //   return;
      // }
      emit(state.copyWith(status: LoadStatus.loading, error: null));
      final result = await ApiService().timingsByCoordinates({
        'latitude': lat,
        'longitude': lng,
        'method': state.method,
      });
      result.fold(
        (failure) {
          emit(
            state.copyWith(status: LoadStatus.error, error: failure.message),
          );
        },
        (response) {
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
        },
      );
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.error, error: e.toString()));
    }
  }

  bool _hasTodayData() {
    final lat = state.lat;
    final lng = state.lng;
    if (lat == null || lng == null) return false;
    final key = _buildKey(lat, lng, state.method);
    return state.lastFetchKey == key && state.prayer != null;
  }

  String _buildKey(double lat, double lng, String method) {
    final now = DateTime.now();
    final d =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '$method|${lat.toStringAsFixed(4)}|${lng.toStringAsFixed(4)}|$d';
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
