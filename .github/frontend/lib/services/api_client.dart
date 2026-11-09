import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'storage_service.dart';

/// Thin wrapper around [http] that:
/// - Prefixes every request with the configured base URL
/// - Attaches the bearer token automatically when available
/// - Normalizes error handling into [ApiException]
class ApiClient {
  final StorageService _storage = StorageService();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) cleanQuery[key] = value.toString();
    });
    return Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: cleanQuery.isEmpty ? null : cleanQuery);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path,
      {Map<String, dynamic>? query, bool auth = true}) async {
    try {
      final res = await http
          .get(_uri(path, query), headers: await _headers(auth: auth))
          .timeout(Duration(seconds: ApiConfig.connectTimeoutSeconds));
      return _handleResponse(res);
    } on SocketException {
      throw ApiException(
          'Could not reach the server. Check your connection or backend URL.');
    }
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: await _headers(auth: auth),
            body: jsonEncode(body ?? {}),
          )
          .timeout(Duration(seconds: ApiConfig.connectTimeoutSeconds));
      return _handleResponse(res);
    } on SocketException {
      throw ApiException(
          'Could not reach the server. Check your connection or backend URL.');
    }
  }

  Future<dynamic> put(String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final res = await http
          .put(
            _uri(path),
            headers: await _headers(auth: auth),
            body: jsonEncode(body ?? {}),
          )
          .timeout(Duration(seconds: ApiConfig.connectTimeoutSeconds));
      return _handleResponse(res);
    } on SocketException {
      throw ApiException(
          'Could not reach the server. Check your connection or backend URL.');
    }
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    try {
      final res = await http
          .delete(_uri(path), headers: await _headers(auth: auth))
          .timeout(Duration(seconds: ApiConfig.connectTimeoutSeconds));
      return _handleResponse(res);
    } on SocketException {
      throw ApiException(
          'Could not reach the server. Check your connection or backend URL.');
    }
  }

  dynamic _handleResponse(http.Response res) {
    final status = res.statusCode;
    dynamic decoded;
    try {
      decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      decoded = null;
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    String message = 'Something went wrong ($status)';
    if (decoded is Map && decoded['detail'] != null) {
      final detail = decoded['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          message = first['msg'].toString();
        } else {
          message = detail.toString();
        }
      }
    }

    throw ApiException(message, statusCode: status);
  }
}
