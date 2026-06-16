import 'package:flutter/services.dart';

class AppChannels {
  static const MethodChannel messaging = MethodChannel('com.rhyn.reach/messaging');
  static const EventChannel inboxEvents = EventChannel('com.rhyn.reach/inbox_events');
  static const EventChannel chatEvents = EventChannel('com.rhyn.reach/chat_events');
}
