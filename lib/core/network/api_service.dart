import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../error/exceptions.dart';
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
    } on RemoteException catch (e) {
      return Left(_mapDioFailure(e.dioError));
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      log('ApiService.getProjects: Unexpected error - $e');
      return Left(UnknownFailure(e.toString()));
    }
  }

  ResultFuture<Response> timingsByCity(
    Map<String, Object> params,
  ) async {
    try {
      final response = await _networkClient.get('/timingsByCity', params);
      return Right(response);
    } on RemoteException catch (e) {
      return Left(_mapDioFailure(e.dioError));
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      log('ApiService.timingsByCity: Unexpected error - $e');
      return Left(UnknownFailure(e.toString()));
    }
  }

  Failure _mapDioFailure(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final responseMessage = _extractApiMessage(responseData);
    final fallback = e.message ?? 'Request failed';
    final message = (responseMessage ?? fallback).trim();

    if (statusCode == 400) {
      return ValidationFailure(message, statusCode: statusCode, errorData: responseData);
    }
    if (statusCode == 401 || statusCode == 403) {
      return AuthenticationFailure(
        message,
        statusCode: statusCode,
        errorData: responseData,
      );
    }
    if (statusCode == 404) {
      return NotFoundFailure(message, statusCode: statusCode, errorData: responseData);
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerFailure(message, statusCode: statusCode, errorData: responseData);
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailure(message, statusCode: statusCode, errorData: responseData);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return TimeoutFailure(message, statusCode: statusCode, errorData: responseData);
    }
    if (e.type == DioExceptionType.cancel) {
      return CancellationFailure(message, statusCode: statusCode, errorData: responseData);
    }
    return ClientFailure(message, statusCode: statusCode, errorData: responseData);
  }

  String? _extractApiMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final raw = responseData['data'] ?? responseData['message'] ?? responseData['status'];
      final message = raw?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}
