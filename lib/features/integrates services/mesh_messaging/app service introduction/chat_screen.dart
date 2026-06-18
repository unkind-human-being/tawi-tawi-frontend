import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/channels/app_channels.dart';

class ChatScreen extends StatefulWidget {
  final String threadId;
  final String displayName;

  const ChatScreen({
    super.key,
    required this.threadId,
    required this.displayName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = [];
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _chatSubscription = AppChannels.chatEvents.receiveBroadcastStream(widget.threadId).listen((dynamic event) {
      if (mounted) {
        setState(() {
          _messages = List<String>.from(event).reversed.toList();
        });
      }
    }, onError: (dynamic error) {
      debugPrint('Chat event error: $error');
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      await AppChannels.messaging.invokeMethod('sendMessage', {
        'threadId': widget.threadId,
        'targetName': widget.displayName.split(' (')[0],
        'messageText': text,
      });
    } catch (e) {
      debugPrint('Failed to send message: $e');
    }
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
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          widget.displayName,
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Say hi over the mesh!',
                      style: TextStyle(color: textMuted),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final rawString = _messages[index];
                      final parts = rawString.split(':::');
                      final sender = parts[0];
                      final text = parts.length > 1 ? parts[1] : '';
                      final isMe = sender == 'You';
                      final timestampStr = parts.length > 2 ? parts[2] : '';
                      final deliveryState = parts.length > 3 ? parts[3] : '';

                      String timeFormatted = '';
                      if (timestampStr.isNotEmpty) {
                        final timeInt = int.tryParse(timestampStr);
                        if (timeInt != null) {
                          final date = DateTime.fromMillisecondsSinceEpoch(timeInt);
                          timeFormatted = '${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
                        }
                      }

                      IconData? statusIcon;
                      if (isMe) {
                        if (deliveryState == 'PENDING') {
                          statusIcon = Icons.access_time;
                        } else if (deliveryState == 'READ') {
                          statusIcon = Icons.done_all;
                        } else {
                          statusIcon = Icons.check; // MESH_ROUTED, LAN_DELIVERED, CLOUD_DELIVERED
                        }
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF0F766E) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    timeFormatted,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : textMuted,
                                    ),
                                  ),
                                  if (isMe && statusIcon != null) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      statusIcon,
                                      size: 12,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: textDark),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: textMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF0F766E)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
