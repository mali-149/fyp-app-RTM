import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/theme/app_theme.dart';
import 'package:skyride/widgets/shimmer_loading.dart';
import './map.dart';
import './call.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String currentUserId;

  const ChatDetailScreen({super.key, required this.user, required this.currentUserId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;
  final String profileImagePath = 'assets/images/user1.jpg';

  late String receiverId;

  @override
  void initState() {
    super.initState();
    receiverId = (widget.user['_id'] ?? widget.user['userId'] ?? widget.user['id']).toString();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await SkyRideApi.instance.getChatHistory(widget.currentUserId, receiverId);
      if (mounted) {
        setState(() {
          messages = history.map((m) => Map<String, dynamic>.from(m)).toList();
          isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(Uri.encodeFull(url));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendMessage(String messageText, {double? latitude, double? longitude}) async {
    if (isSending) return;
    setState(() {
      isSending = true;
      messageController.clear();
    });

    try {
      await SkyRideApi.instance.sendMessage(
        senderId: widget.currentUserId,
        receiverId: receiverId,
        message: messageText,
        latitude: latitude,
        longitude: longitude,
      );

      await _loadChatHistory();

      final sender = await SkyRideApi.instance.getUserById(widget.currentUserId);
      final senderRole = sender?['role'] as String? ?? 'user';
      final receiverRole = widget.user['role'] as String? ?? '';

      if (senderRole == 'user' && (receiverRole == 'machanic' || receiverRole == 'fuelpump')) {
        final history = await SkyRideApi.instance.getChatHistory(widget.currentUserId, receiverId);
        final providerMessages = history.where((m) => m['sender_id'] == receiverId).length;
        if (providerMessages <= 1) {
          Future.delayed(const Duration(seconds: 1), () async {
            final reply = receiverRole == 'machanic'
                ? "I'm on my way. Please share more details about the problem."
                : "We can deliver fuel to your location. Please confirm the fuel type and quantity.";
            await SkyRideApi.instance.sendMessage(
              senderId: receiverId,
              receiverId: widget.currentUserId,
              message: reply,
            );
            if (mounted) await _loadChatHistory();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<LocationData?> _determinePosition() async {
    final location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await location.requestService();

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    if (permission == PermissionStatus.granted || permission == PermissionStatus.grantedLimited) {
      return location.getLocation();
    }
    return null;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == widget.currentUserId;
    final messageText = msg['message'] as String? ?? '';
    final isLocation = messageText.startsWith("📍 Shared location:");

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary.withOpacity(0.85) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLocation
            ? GestureDetector(
                onTap: () {
                  final url = messageText.replaceFirst("📍 Shared location: ", "").trim();
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    final query = uri.queryParameters['q'];
                    if (query != null) {
                      final coords = query.split(',');
                      if (coords.length == 2) {
                        final lat = double.tryParse(coords[0]);
                        final lng = double.tryParse(coords[1]);
                        if (lat != null && lng != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ViewLocationScreen(latitude: lat, longitude: lng)),
                          );
                          return;
                        }
                      }
                    }
                  }
                  _launchURL(url);
                },
                child: Text(
                  messageText,
                  style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                ),
              )
            : Text(
                messageText,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.chatBackground,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.user['username'] ?? 'Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioCallScreen(
                      username: widget.user['username'] ?? 'User',
                      profileImagePath: profileImagePath,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: isLoading
            ? const ShimmerChatDetail()
            : messages.isEmpty
                ? const Center(child: Text("No messages yet. Start the conversation!"))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
                  ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.location_on, color: AppTheme.primary),
                  iconSize: 26,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () async {
                    if (!isSending) {
                      final position = await _determinePosition();
                      if (position?.latitude != null && position?.longitude != null) {
                        final locMessage =
                            "📍 Shared location: https://maps.google.com/?q=${position!.latitude},${position.longitude}";
                        await _sendMessage(
                          locMessage,
                          latitude: position.latitude,
                          longitude: position.longitude,
                        );
                      }
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty && !isSending) {
                        _sendMessage(value.trim());
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                isSending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: AppTheme.primary),
                        iconSize: 26,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        onPressed: () {
                          final text = messageController.text.trim();
                          if (text.isNotEmpty) _sendMessage(text);
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
