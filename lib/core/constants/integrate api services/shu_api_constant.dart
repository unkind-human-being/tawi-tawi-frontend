class ShuApiConstants {
  // Social Health / RHU backend
  // This is separate from the main Tawi-Tawi backend.
  static const String baseUrl = String.fromEnvironment(
    'SOCIAL_HEALTH_API_BASE_URL',
    defaultValue: 'https://rhu-project.onrender.com',
  );

  static const String login = '$baseUrl/api/auth/login';

  static const String me = '$baseUrl/api/auth/me';

  static const String register = '$baseUrl/api/auth/register';

  static const String posts = '$baseUrl/api/posts/public';

  static const String events = '$baseUrl/api/events/public';

  static const String surveys = '$baseUrl/api/surveys/public';

  static const String appointments = '$baseUrl/api/appointments';

  static const String rhuAiChat = String.fromEnvironment(
    'RHU_AI_CHAT_URL',
    defaultValue: 'https://rhu-ai.onrender.com/api/ai/chat',
  );
}