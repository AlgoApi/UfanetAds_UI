import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  final _baseUrl = dotenv.env['API_URL']!;

  Future<http.Response> get(Uri path, {Map<String, String>? params}) =>
      _send('GET', path, params: params);

  Future<http.Response> post(Uri path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<http.Response> _send(
      String method,
      Uri path, {
        Map<String, String>? params,
        Object? body,
      }) async {
    final token = await AuthStorage().readToken();

    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: json.encode(body));
      default:
        throw UnsupportedError('Метод $method не поддерживается');
    }
  }
}
