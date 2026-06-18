import 'package:flutter/material.dart';
import 'package:ui_testing/core/services/api_service.dart';
import 'package:ui_testing/core/services/socket.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String userB;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.userB,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> messages = [];
  late String roomId;

  // Determine if current user is user_1
  bool get isCurrentUser => widget.currentUserId == '6a33c96a07149162a1c676c2';

  @override
  void initState() {
    super.initState();
    roomId = ([widget.currentUserId, widget.userB]..sort()).join('_');
    initChat();
  }

  Future<void> initChat() async {
    // 1. Load old messages from API
    final res = await ApiService.getChat(widget.currentUserId, widget.userB);

    if (res.isSuccess) {
      setState(() {
        messages = res.data ?? [];
      });
      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    // 2. Connect socket listener
    SocketService.socket.emit('join_room', roomId);

    SocketService.socket.off('message');
    SocketService.socket.on('message', (data) {
      setState(() {
        messages.add(data);
      });
      // Auto-scroll to bottom when new message arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = {
      "roomId": roomId,
      "senderId": widget.currentUserId,
      "message": text,
      "timestamp": DateTime.now().toIso8601String(),
    };

    // send via socket
    SocketService.socket.emit('message', msg);

    _controller.clear();
  }

  // Check if a message belongs to current user (user_1)
  bool _isMyMessage(dynamic msg) {
    return msg['senderId'] == '6a33c96a07149162a1c676c2';
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade700,
              child: Text(
                widget.userB.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userB,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // CHAT LIST
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 15,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMyMsg = _isMyMessage(msg);
                  final timeStr = _formatTime(msg['timestamp']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: isMyMsg
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Show avatar for other user's messages
                        if (!isMyMsg) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade400,
                            child: Text(
                              (msg['senderId']?.toString().substring(0, 1) ??
                                      '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Message bubble
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMyMsg
                                  ? Colors.blue.shade600
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMyMsg ? 18 : 4),
                                bottomRight: Radius.circular(isMyMsg ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['message'] ?? '',
                                  style: TextStyle(
                                    color: isMyMsg
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMyMsg
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Show check mark for my messages
                        if (isMyMsg) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // INPUT BOX
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade600.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: sendMessage,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    SocketService.socket.off('message');
    super.dispose();
  }
}
