import 'dart:async';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String vendorId;
  final String productName;

  const ChatDetailScreen({
    super.key,
    required this.productId,
    required this.vendorId,
    required this.productName,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  dynamic _conversation;
  bool _isLoading = true;
  bool _isSending = false; // Added to prevent spam clicking
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initChat();

    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) _initChat();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/chat/conversation', data: {
        'productId': widget.productId,
        'vendorId': widget.vendorId,
      });

      if (mounted) {
        setState(() {
          _conversation = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Chat Error: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || _isSending) return;

    final content = _msgController.text.trim();

    // Set sending state to true and clear the text field immediately for good UX
    setState(() {
      _isSending = true;
      _msgController.clear();
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/chat/message', data: {
        'conversationId': _conversation['id'],
        'content': content,
      });
      // Fetch the updated chat immediately after sending
      await _initChat();
    } catch (e) {
      debugPrint("Send Error: $e");
      // If it fails, you might want to put the text back
      setState(() => _msgController.text = content);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final String currentUserId = authState?.user.id ?? '';

    final List messages =
        (_conversation != null && _conversation['messages'] != null)
            ? (_conversation['messages'] as List).reversed.toList()
            : [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: Text(widget.productName,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No messages yet.",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16)),
                              Text("Start the conversation!",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          reverse:
                              true, // Keeps the newest messages at the bottom
                          itemCount: messages.length,
                          itemBuilder: (ctx, i) {
                            final msg = messages[i];
                            final bool isMe = msg['senderId'] == currentUserId;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width *
                                      0.75, // Don't let bubbles stretch all the way across
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blueGrey.shade800
                                      : Colors.white,
                                  border: isMe
                                      ? null
                                      : Border.all(color: Colors.grey.shade200),
                                  // --- MODERN SPEECH BUBBLE CORNERS ---
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                    bottomRight: isMe
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                                  ),
                                  boxShadow: isMe
                                      ? []
                                      : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2))
                                        ],
                                ),
                                child: Text(
                                  msg['content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isMe ? Colors.white : Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // --- CLEAN TEXT INPUT AREA ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2))
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Send Button / Loading Spinner
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade900,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send,
                                    color: Colors.white, size: 20),
                            onPressed: _isSending ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
