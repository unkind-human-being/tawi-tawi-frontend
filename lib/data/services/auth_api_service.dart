import '../../core/services/api_service.dart';

class AuthApiService {
  final ApiService _apiService;

  AuthApiService(this._apiService);

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    const String mutation = r'''
      mutation RegisterUser($fullName: String!, $email: String!, $password: String!) {
        register(fullName: $fullName, email: $email, password: $password) {
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

    final Map<String, dynamic> data = await _apiService.graphql(
      query: mutation,
      variables: <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'password': password,
      },
    );

    return _wrapAuthResponse(data, 'register');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    const String mutation = r'''
      mutation LoginUser($email: String!, $password: String!) {
        login(email: $email, password: $password) {
          token
          user {
            id
            fullName
            email
          }
        }
      }
    ''';

    final Map<String, dynamic> data = await _apiService.graphql(
      query: mutation,
      variables: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );

    return _wrapAuthResponse(data, 'login');
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    const String mutation = r'''
      mutation GoogleLogin($idToken: String!) {
        googleLogin(idToken: $idToken) {
          token
          user {
            id
            fullName
            email
          }
        }
      }
    ''';

    final Map<String, dynamic> data = await _apiService.graphql(
      query: mutation,
      variables: <String, dynamic>{
        'idToken': idToken,
      },
    );

    return _wrapAuthResponse(data, 'googleLogin');
  }

  Future<Map<String, dynamic>> loginWithMeta({
    required String accessToken,
  }) async {
    const String mutation = r'''
      mutation MetaLogin($accessToken: String!) {
        metaLogin(accessToken: $accessToken) {
          token
          user {
            id
            fullName
            email
          }
        }
      }
    ''';

    final Map<String, dynamic> data = await _apiService.graphql(
      query: mutation,
      variables: <String, dynamic>{
        'accessToken': accessToken,
      },
    );

    return _wrapAuthResponse(data, 'metaLogin');
  }

  Future<Map<String, dynamic>> getMe({
    required String token,
  }) async {
    const String query = r'''
      query Me {
        me {
          id
          fullName
          email
          status
        }
      }
    ''';

    final Map<String, dynamic> data = await _apiService.graphql(
      query: query,
      token: token,
    );

    final dynamic user = data['me'];

    if (user is! Map<String, dynamic>) {
      throw Exception('Unable to load current user.');
    }

    return <String, dynamic>{
      'data': <String, dynamic>{
        'user': user,
      },
    };
  }

  Future<Map<String, dynamic>> updateMe({
    required String token,
    required String fullName,
  }) async {
    const String mutation = r'''
      mutation UpdateMe($fullName: String!) {
        updateMe(fullName: $fullName) {
          id
          fullName
          email
          status
        }
      }
    ''';

    final Map<String, dynamic> data = await _apiService.graphql(
      query: mutation,
      token: token,
      variables: <String, dynamic>{
        'fullName': fullName,
      },
    );

    final dynamic user = data['updateMe'];

    if (user is! Map<String, dynamic>) {
      throw Exception('Unable to update profile.');
    }

    return <String, dynamic>{
      'data': <String, dynamic>{
        'user': user,
      },
    };
  }

  Future<Map<String, dynamic>> logout({
    required String token,
  }) async {
    // JWT logout is local. Backend logout is not required unless your
    // GraphQL backend adds a logout mutation later.
    return <String, dynamic>{
      'success': true,
      'message': 'Logged out locally.',
    };
  }

  Map<String, dynamic> _wrapAuthResponse(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic authPayload = data[key];

    if (authPayload is! Map<String, dynamic>) {
      throw Exception('Invalid authentication response.');
    }

    final dynamic token = authPayload['token'];
    final dynamic user = authPayload['user'];

    if (token == null || token.toString().trim().isEmpty) {
      throw Exception('Authentication token was not returned.');
    }

    if (user is! Map<String, dynamic>) {
      throw Exception('User data was not returned.');
    }

    return <String, dynamic>{
      'data': <String, dynamic>{
        'token': token.toString(),
        'user': user,
      },
    };
  }
}