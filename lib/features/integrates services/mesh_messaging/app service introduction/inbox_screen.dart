import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'nearby_screen.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  static const platform = MethodChannel('com.rhyn.reach/messaging');
  static const inboxEvents = EventChannel('com.rhyn.reach/inbox_events');
  List<String> _messages = [];
  bool _isLoading = true;
  bool _showIntroBanner = false;
  StreamSubscription? _inboxSubscription;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _inboxSubscription = inboxEvents.receiveBroadcastStream().listen((dynamic event) {
      if (mounted) {
        setState(() {
          _messages = List<String>.from(event);
          _isLoading = false;
        });
      }
    }, onError: (dynamic error) {
      debugPrint('Inbox event error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenIntro = prefs.getBool('has_seen_messaging_intro') ?? false;
    
    if (!hasSeenIntro && mounted) {
      setState(() {
        _showIntroBanner = true;
      });
    }
  }

  void _dismissIntroBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_messaging_intro', true);
    if (mounted) {
      setState(() {
        _showIntroBanner = false;
      });
    }
  }

  @override
  void dispose() {
    _inboxSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Inbox',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.sensors_rounded, color: textDark),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NearbyScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          if (_showIntroBanner)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.forum_rounded, color: Color(0xFF0F766E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Welcome to Messaging',
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF0F766E)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _dismissIntroBanner,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This feature allows you to connect with others. It also supports offline messaging, allowing you to communicate even without an active internet connection via nearby devices!',
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.\nMessages from Kotlin will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final rawString = _messages[index];
                          
                          if (rawString.startsWith('System:')) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                rawString,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textMuted),
                              ),
                            );
                          }

                    if (!rawString.contains(':::')) {
                      return ListTile(title: Text(rawString, style: TextStyle(color: textDark)));
                    }

                    final parts = rawString.split(':::');
                    if (parts.length < 3) return const SizedBox.shrink();

                    final threadId = parts[0];
                    final senderName = parts[1];
                    final messagePreview = parts[2];
                    final timestampStr = parts.length > 3 ? parts[3] : '';

                    String timeFormatted = '';
                    if (timestampStr.isNotEmpty) {
                      final timeInt = int.tryParse(timestampStr);
                      if (timeInt != null) {
                        final date = DateTime.fromMillisecondsSinceEpoch(timeInt);
                        timeFormatted = '${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                        child: const Icon(Icons.person, color: Color(0xFF0F766E)),
                      ),
                      title: Text(
                        senderName,
                        style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        messagePreview,
                        style: TextStyle(color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: timeFormatted.isNotEmpty 
                          ? Text(timeFormatted, style: TextStyle(color: textMuted, fontSize: 12)) 
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              threadId: threadId,
                              displayName: senderName == 'You' ? 'Chat' : senderName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
