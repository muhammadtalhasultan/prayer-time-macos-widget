import 'package:dio/dio.dart';
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errorData;

  const AppException({required this.message, this.statusCode, this.errorData});

  @override
  String toString() => message;
}

class RemoteException implements Exception {
  DioException dioError;

  RemoteException({required this.dioError});
}
