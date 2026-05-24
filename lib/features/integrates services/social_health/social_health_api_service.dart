import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/integrate api services/shu/shu_api_constant.dart';

class SocialHealthApiService {
  static const String _loginMutation = r'''
mutation LoginUser($email: String!, $password: String!) {
  login(email: $email, password: $password) {
    token
    user {
      id
      fullName
      email
      status
    }
  }
}
''';

  static const String _meQuery = r'''
query Me {
  me {
    id
    fullName
    email
    status
  }
}
''';

  static const String _verifyServiceAccessQuery = r'''
query VerifyServiceAccess($serviceName: String!) {
  verifyServiceAccess(serviceName: $serviceName) {
    serviceName
    hasAccess
    requiresRegistration
    message
  }
}
''';

  static const String _registerForServiceMutation = r'''
mutation RegisterForService($serviceName: String!, $payload: String!) {
  registerForService(serviceName: $serviceName, payload: $payload) {
    serviceName
    hasAccess
    requiresRegistration
    message
  }
}
''';

  Future<SocialHealthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse(ShuApiConstants.graphql),
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'query': _loginMutation,
            'variables': <String, dynamic>{
              'email': email,
              'password': password,
            },
          }),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint('SHU LOGIN URL: ${ShuApiConstants.graphql}');
    debugPrint('SHU LOGIN STATUS: ${response.statusCode}');
    debugPrint('SHU LOGIN BODY: ${response.body}');

    final Map<String, dynamic> decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwIfGraphqlHasErrors(decoded);

      throw Exception(
        decoded['message']?.toString() ?? 'Social Health login failed.',
      );
    }

    _throwIfGraphqlHasErrors(decoded);

    final Map<String, dynamic> loginData = _readLoginData(decoded);

    final String token = _readString(
      loginData,
      <String>['token', 'accessToken', 'jwt'],
    );

    if (token.trim().isEmpty) {
      throw Exception('Login successful but no token was returned.');
    }

    final Map<String, dynamic> user = _readUser(loginData);

    final SocialHealthServiceAccessResult serviceAccess =
        await verifyServiceAccess(
      token: token,
      serviceName: ShuApiConstants.serviceName,
    );

    if (!serviceAccess.hasAccess && serviceAccess.requiresRegistration) {
      throw Exception(serviceAccess.message);
    }

    if (!serviceAccess.hasAccess) {
      throw Exception(
        serviceAccess.message.isNotEmpty
            ? serviceAccess.message
            : 'Your account has no access to the RHU Social Health service yet.',
      );
    }

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
      role: 'public_user',
      status: _readString(
        user,
        <String>['status'],
        fallback: 'active',
      ),
    );
  }

  Future<SocialHealthServiceAccessResult> verifyServiceAccess({
    required String token,
    required String serviceName,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse(ShuApiConstants.graphql),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(<String, dynamic>{
            'query': _verifyServiceAccessQuery,
            'variables': <String, dynamic>{
              'serviceName': serviceName,
            },
          }),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint('SHU VERIFY SERVICE STATUS: ${response.statusCode}');
    debugPrint('SHU VERIFY SERVICE BODY: ${response.body}');

    final Map<String, dynamic> decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwIfGraphqlHasErrors(decoded);
      throw Exception('Unable to verify Social Health access.');
    }

    _throwIfGraphqlHasErrors(decoded);

    return _readServiceAccessResult(
      decoded,
      key: 'verifyServiceAccess',
      fallbackServiceName: serviceName,
      fallbackMessage: 'Unable to verify RHU Social Health access.',
    );
  }

  Future<SocialHealthServiceAccessResult> registerForService({
    required String token,
    required String serviceName,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse(ShuApiConstants.graphql),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(<String, dynamic>{
            'query': _registerForServiceMutation,
            'variables': <String, dynamic>{
              'serviceName': serviceName,
              'payload': jsonEncode(payload),
            },
          }),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint('SHU REGISTER SERVICE STATUS: ${response.statusCode}');
    debugPrint('SHU REGISTER SERVICE BODY: ${response.body}');

    final Map<String, dynamic> decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwIfGraphqlHasErrors(decoded);
      throw Exception('Unable to create RHU account.');
    }

    _throwIfGraphqlHasErrors(decoded);

    return _readServiceAccessResult(
      decoded,
      key: 'registerForService',
      fallbackServiceName: serviceName,
      fallbackMessage: 'Unable to create RHU account.',
    );
  }

  Future<bool> checkToken(String token) async {
    if (token.trim().isEmpty) {
      return false;
    }

    try {
      final http.Response response = await http
          .post(
            Uri.parse(ShuApiConstants.graphql),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, dynamic>{
              'query': _meQuery,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final Map<String, dynamic> decoded = _decodeResponse(response);

      final dynamic errors = decoded['errors'];

      if (errors is List && errors.isNotEmpty) {
        return false;
      }

      final dynamic data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        return false;
      }

      return data['me'] != null;
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final String body = response.body.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    if (body.startsWith('<!DOCTYPE html') || body.startsWith('<html')) {
      throw Exception(
        'Backend returned HTML instead of JSON. Check if the app is calling the correct /graphql endpoint.',
      );
    }

    try {
      final dynamic decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{};
    } catch (_) {
      throw Exception('Invalid backend response. Expected JSON.');
    }
  }

  void _throwIfGraphqlHasErrors(Map<String, dynamic> json) {
    final dynamic errors = json['errors'];

    if (errors is List && errors.isNotEmpty) {
      final dynamic firstError = errors.first;

      if (firstError is Map<String, dynamic>) {
        final dynamic message = firstError['message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          throw Exception(message.toString());
        }
      }

      throw Exception('Social Health request failed.');
    }
  }

  Map<String, dynamic> _readLoginData(Map<String, dynamic> json) {
    final dynamic data = json['data'];

    if (data is Map<String, dynamic>) {
      final dynamic login = data['login'];

      if (login is Map<String, dynamic>) {
        return login;
      }

      final dynamic loginUser = data['loginUser'];

      if (loginUser is Map<String, dynamic>) {
        return loginUser;
      }

      final dynamic socialHealthLogin = data['socialHealthLogin'];

      if (socialHealthLogin is Map<String, dynamic>) {
        return socialHealthLogin;
      }
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic> _readUser(Map<String, dynamic> loginData) {
    final dynamic user = loginData['user'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    return <String, dynamic>{};
  }

  SocialHealthServiceAccessResult _readServiceAccessResult(
    Map<String, dynamic> json, {
    required String key,
    required String fallbackServiceName,
    required String fallbackMessage,
  }) {
    final dynamic data = json['data'];

    if (data is Map<String, dynamic>) {
      final dynamic result = data[key];

      if (result is Map<String, dynamic>) {
        return SocialHealthServiceAccessResult(
          serviceName: _readString(
            result,
            <String>['serviceName'],
            fallback: fallbackServiceName,
          ),
          hasAccess: result['hasAccess'] == true,
          requiresRegistration: result['requiresRegistration'] == true,
          message: _readString(
            result,
            <String>['message'],
            fallback: '',
          ),
        );
      }
    }

    return SocialHealthServiceAccessResult(
      serviceName: fallbackServiceName,
      hasAccess: false,
      requiresRegistration: false,
      message: fallbackMessage,
    );
  }
}

class SocialHealthLoginResult {
  const SocialHealthLoginResult({
    required this.token,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  final String token;
  final String name;
  final String email;
  final String role;
  final String status;
}

class SocialHealthServiceAccessResult {
  const SocialHealthServiceAccessResult({
    required this.serviceName,
    required this.hasAccess,
    required this.requiresRegistration,
    required this.message,
  });

  final String serviceName;
  final bool hasAccess;
  final bool requiresRegistration;
  final String message;
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