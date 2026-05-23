class ApiConstants {
  // Main Tawi-Tawi backend
  // New backend uses GraphQL.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tawi-tawi-backend.onrender.com',
  );

  static const String graphql = '$baseUrl/graphql';

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String metaAppId = String.fromEnvironment(
    'META_APP_ID',
    defaultValue: '',
  );
}