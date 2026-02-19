import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../error/failures.dart';
import '../error/typedefs.dart';
import 'network_client.dart';

class ApiService {
  static final ApiService _service = ApiService._internal();

  factory ApiService() {
    return _service;
  }

  ApiService._internal();

  late NetworkClient _networkClient;

  void initApiService() {
    _networkClient = NetworkClient('https://api.aladhan.com/v1');
  }

  ResultFuture<Response> timingsByCoordinates(
    Map<String, Object> params,
  ) async {
    try {
      final response = await _networkClient.get('/timings', params);
      return Right(response);
    } catch (e) {
      log('ApiService.getProjects: Unexpected error - $e');
      return Left(UnknownFailure(e.toString()));
    }
  }
}
