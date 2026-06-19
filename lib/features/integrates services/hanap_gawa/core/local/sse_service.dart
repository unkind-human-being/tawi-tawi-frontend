import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../api/marketplace_api.dart'; // To get the base URL and auth token

class SseEvent {
  final String event;
  final String data;

  SseEvent({required this.event, required this.data});
}

class SseService {
  // Singleton pattern
  static final SseService _instance = SseService._internal();
  factory SseService() => _instance;
  SseService._internal();

  http.Client? _client;
  StreamSubscription<List<int>>? _subscription;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  // Global event controller
  final _eventController = StreamController<SseEvent>.broadcast();
  Stream<SseEvent> get eventStream => _eventController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    final token = MarketplaceApi.apiToken;
    if (token == null || token.isEmpty) {
      log('[SseService] Cannot connect without an API token.');
      return;
    }

    _client = http.Client();
    final url = Uri.parse('\${MarketplaceApi.baseUrl}/events/stream');
    final request = http.Request('GET', url);
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        log('[SseService] Connected to SSE Stream');
        _isConnected = true;
        _reconnectAttempts = 0;

        String buffer = '';
        String currentEvent = 'message';

        _subscription = response.stream
            .transform(const Utf8Decoder())
            .listen((String data) {
          final lines = data.split('\n');

          for (final line in lines) {
            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              buffer += line.substring(5).trim();
            } else if (line.isEmpty && buffer.isNotEmpty) {
              // Dispatch event
              _eventController.add(SseEvent(event: currentEvent, data: buffer));
              buffer = '';
              currentEvent = 'message'; // reset to default
            }
          }
        }, onDone: () {
          log('[SseService] Connection closed by server.');
          _disconnectAndReconnect();
        }, onError: (error) {
          log('[SseService] Stream error: $error');
          _disconnectAndReconnect();
        });
      } else {
        log('[SseService] Failed to connect: \${response.statusCode}');
        _disconnectAndReconnect();
      }
    } catch (e) {
      log('[SseService] Error connecting: $e');
      _disconnectAndReconnect();
    }
  }

  void _disconnectAndReconnect() {
    disconnect();
    
    // Exponential backoff up to ~30 seconds
    _reconnectAttempts++;
    final delay = (1 << (_reconnectAttempts > 5 ? 5 : _reconnectAttempts)) * 1000;
    
    log('[SseService] Reconnecting in \${delay}ms...');
    Timer(Duration(milliseconds: delay), () {
      connect();
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    _isConnected = false;
  }
}
