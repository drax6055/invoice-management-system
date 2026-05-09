import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.tokenStore,
    http.Client? httpClient,
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://invoice-management-system-3g22.onrender.com/api',
    ),
  }) : _http = httpClient ?? http.Client();

  final TokenStore tokenStore;
  final String baseUrl;
  final http.Client _http;

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    return _send(() => _http.get(uri, headers: _headers()));
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final uri = _uri(path);
    return _send(
        () => _http.post(uri, headers: _headers(), body: jsonEncode(body)));
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    final uri = _uri(path);
    return _send(
        () => _http.patch(uri, headers: _headers(), body: jsonEncode(body)));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = _uri(path);
    return _send(() => _http.delete(uri, headers: _headers()));
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (tokenStore.cachedAccessToken != null)
        'Authorization': 'Bearer ${tokenStore.cachedAccessToken}',
    };
  }

  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() request) async {
    final response = await request();
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }
}
