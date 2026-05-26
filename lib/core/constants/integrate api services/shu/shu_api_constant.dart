import '../../api_constants.dart';

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

  static const String myAppointments = '$gatewayPrefix/appointments/my';

  static const String appointments = '$gatewayPrefix/appointments';


  static const String appointmentPhotoUpload =
      '$gatewayPrefix/uploads/appointment-photo';

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

  static String consultationMessagesForAppointment(String appointmentId) {
    return '$gatewayPrefix/consultation-messages/appointment/$appointmentId';
  }

  static const String myNotifications = '$gatewayPrefix/notifications/my';

  static const String unreadNotificationsCount =
      '$gatewayPrefix/notifications/unread-count';

  static const String markAllNotificationsRead =
      '$gatewayPrefix/notifications/read-all';

  static String markNotificationRead(String notificationId) {
    return '$gatewayPrefix/notifications/$notificationId/read';
  }


  static const String incomingVideoCall =
    '$gatewayPrefix/video/calls/incoming';

  static const String agoraToken =
      '$gatewayPrefix/video/agora-token';

  static const String videoCallJoined =
      '$gatewayPrefix/video/calls/joined';

  static const String videoCallEnded =
      '$gatewayPrefix/video/calls/ended';

  static String acceptVideoCall(String callId) {
    return '$gatewayPrefix/video/calls/$callId/accept';
  }

  static String declineVideoCall(String callId) {
    return '$gatewayPrefix/video/calls/$callId/decline';
  }

  static String endVideoCall(String callId) {
    return '$gatewayPrefix/video/calls/$callId/end';
  }


  static const String rhuAiChat = '$gatewayPrefix/ai/chat';
}