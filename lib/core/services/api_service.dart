import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ApiService {
  Future<Map<String, dynamic>> get(
    String url, {
    String? token,
  }) async {
    final http.Response response = await http
        .get(
          Uri.parse(url),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 25));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse(url),
          headers: _headers(token: token),
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 25));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final http.Response response = await http
        .patch(
          Uri.parse(url),
          headers: _headers(token: token),
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 25));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> graphql({
    required String query,
    Map<String, dynamic> variables = const <String, dynamic>{},
    String? token,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse(ApiConstants.graphql),
          headers: _headers(token: token),
          body: jsonEncode(<String, dynamic>{
            'query': query,
            'variables': variables,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final Map<String, dynamic> decoded = _handleResponse(response);

    final dynamic errors = decoded['errors'];

    if (errors is List && errors.isNotEmpty) {
      final dynamic firstError = errors.first;

      if (firstError is Map<String, dynamic>) {
        final dynamic message = firstError['message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          throw Exception(message.toString());
        }
      }

      throw Exception('GraphQL request failed.');
    }

    final dynamic data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid GraphQL response.');
    }

    return data;
  }

  Map<String, String> _headers({String? token}) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final String rawBody = response.body.trim();

    Map<String, dynamic> decoded = <String, dynamic>{};

    if (rawBody.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(rawBody);

        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        } else {
          throw Exception('Invalid server response format.');
        }
      } on FormatException {
        if (rawBody.startsWith('<!DOCTYPE') || rawBody.startsWith('<html')) {
          throw Exception(
            'Server returned HTML instead of JSON. Check if the API URL is correct.',
          );
        }

        throw Exception('Server returned invalid JSON.');
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final String message = _readErrorMessage(decoded);

    throw Exception(message);
  }

  String _readErrorMessage(Map<String, dynamic> decoded) {
    final dynamic message = decoded['message'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final dynamic error = decoded['error'];

    if (error != null && error.toString().trim().isNotEmpty) {
      return error.toString();
    }

    final dynamic errors = decoded['errors'];

    if (errors is List && errors.isNotEmpty) {
      final dynamic firstError = errors.first;

      if (firstError is Map<String, dynamic>) {
        final dynamic graphQlMessage = firstError['message'];

        if (graphQlMessage != null &&
            graphQlMessage.toString().trim().isNotEmpty) {
          return graphQlMessage.toString();
        }
      }

      return 'GraphQL request failed.';
    }

    return 'Something went wrong.';
  }
}