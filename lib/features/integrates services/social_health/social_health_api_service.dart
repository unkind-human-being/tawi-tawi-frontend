import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/integrate api services/shu_api_constant.dart';

class SocialHealthApiService {
  Future<SocialHealthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse(ShuApiConstants.login),
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 25));

    final Map<String, dynamic> decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ?? 'Social Health login failed.',
      );
    }

    final String token = _readToken(decoded);

    if (token.trim().isEmpty) {
      throw Exception('Login successful but no token was returned.');
    }

    final Map<String, dynamic> user = _readUser(decoded);

    return SocialHealthLoginResult(
      token: token,
      name: _readString(
        user,
        <String>['fullName', 'name', 'displayName'],
        fallback: 'Social Health User',
      ),
      email: _readString(
        user,
        <String>['email', 'username'],
        fallback: email,
      ),
      role: _readString(
        user,
        <String>['role'],
        fallback: 'public_user',
      ),
    );
  }

  Future<bool> checkToken(String token) async {
    if (token.trim().isEmpty) {
      return false;
    }

    try {
      final http.Response response = await http
          .get(
            Uri.parse(ShuApiConstants.me),
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      // If /me is not available or internet is slow,
      // keep local session instead of forcing logout.
      return true;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  String _readToken(Map<String, dynamic> json) {
    final String directToken = _readString(
      json,
      <String>['token', 'accessToken', 'jwt'],
    );

    if (directToken.trim().isNotEmpty) {
      return directToken;
    }

    final dynamic data = json['data'];

    if (data is Map<String, dynamic>) {
      final String dataToken = _readString(
        data,
        <String>['token', 'accessToken', 'jwt'],
      );

      if (dataToken.trim().isNotEmpty) {
        return dataToken;
      }
    }

    return '';
  }

  Map<String, dynamic> _readUser(Map<String, dynamic> json) {
    final dynamic user = json['user'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    final dynamic data = json['data'];

    if (data is Map<String, dynamic>) {
      final dynamic dataUser = data['user'];

      if (dataUser is Map<String, dynamic>) {
        return dataUser;
      }

      return data;
    }

    return <String, dynamic>{};
  }
}

class SocialHealthLoginResult {
  const SocialHealthLoginResult({
    required this.token,
    required this.name,
    required this.email,
    required this.role,
  });

  final String token;
  final String name;
  final String email;
  final String role;
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final String key in keys) {
    final dynamic value = json[key];

    if (value == null) {
      continue;
    }

    final String text = value.toString().trim();

    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }

  return fallback;
}