import 'dart:developer';
import 'package:dio/dio.dart';
import '../error/exceptions.dart';

class NetworkClient {
  Dio _dio = Dio();

  NetworkClient(String baseUrl) {
    BaseOptions baseOptions = BaseOptions(
      receiveTimeout: const Duration(seconds: 100),
      connectTimeout: const Duration(seconds: 100),
      baseUrl: baseUrl,
      maxRedirects: 2,
    );
    _dio = Dio(baseOptions);
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        error: true,
        request: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: true,
        logPrint: (object) => log('Log: $object'),
      ),
    );
  }

  // for HTTP.GET Request.
  Future<Response> get(String url, Map<String, dynamic> params) async {
    Response response;
    try {
      response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(responseType: ResponseType.json),
      );
    } on DioException catch (exception) {
      throw RemoteException(dioError: exception);
    }
    return response;
  }

  // for HTTP.POST Request.
  Future<Response> post(String url, dynamic params) async {
    Response response;
    try {
      response = await _dio.post(
        url,
        data: params,
        options: Options(
          responseType: ResponseType.json,
          contentType: Headers.jsonContentType,
        ),
      );
    } on DioException catch (exception) {
     throw RemoteException(dioError: exception);
    }
    return response;
  }

  // for HTTP.PUT Request.
  Future<Response> put(String url, Map<String, dynamic> params) async {
    Response response;
    try {
      response = await _dio.put(
        url,
        data: params,
        options: Options(responseType: ResponseType.json),
      );
    } on DioException catch (exception) {
      throw RemoteException(dioError: exception);
    }
    return response;
  }

  Future<Response> patch(String url, Map<String, dynamic> params) async {
    Response response;
    try {
      response = await _dio.patch(
        url,
        data: params,
        options: Options(responseType: ResponseType.json),
      );
    } on DioException catch (exception) {
     throw RemoteException(dioError: exception);
    }
    return response;
  }

  // for HTTP.DELETE Request.
  Future<Response> delete(String url, dynamic params) async {
    Response response;
    try {
      response = await _dio.delete(
        url,
        data: params,
        options: Options(responseType: ResponseType.json),
      );
    } on DioException catch (exception) {
    throw RemoteException(dioError: exception);
    }
    return response;
  }

  // for dwonload Request.
  Future<Response> download(
    String url,
    String pathName,
    void Function(int, int)? onReceiveProgress,
  ) async {
    Response response;
    try {
      response = await _dio.download(
        url,
        pathName,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (exception) {
     throw RemoteException(dioError: exception);
    }
    return response;
  }
}
