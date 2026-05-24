import '../api_constants.dart';

class ShuApiConstants {
  // Main Tawi-Tawi backend
  static const String baseUrl = ApiConstants.baseUrl;

  // GraphQL endpoint:
  // Flutter -> Tawi-Tawi Backend /graphql
  static const String graphql = ApiConstants.graphql;

  // IMPORTANT:
  // This must match the service name registered in:
  // tawi-tawi-backend/src/gateway/serviceClients.js
  //
  // Your backend service name is "shu", not "rhu".
  static const String serviceName = 'shu';

  // REST proxy route mounted by Tawi-Tawi backend:
  // app.use('/api/shu', proxy)
  static const String gatewayPrefix = '$baseUrl/api/shu';

  static const String posts = '$gatewayPrefix/posts/public';

  static const String events = '$gatewayPrefix/events/public';

  static const String surveys = '$gatewayPrefix/surveys/public';

  static String eventRegistration(String eventId) {
    return '$gatewayPrefix/event-registrations/event/$eventId';
  }

  static String surveyResponse(String surveyId) {
    return '$gatewayPrefix/survey-responses/survey/$surveyId';
  }

  static const String rhus = '$gatewayPrefix/rhus';

  static String appointmentSetting(String rhuId) {
    return '$gatewayPrefix/appointment-settings/rhu/$rhuId';
  }

  static const String rhuAiChat = '$gatewayPrefix/ai/chat';
}