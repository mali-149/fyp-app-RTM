import 'package:flutter/material.dart';
import 'package:skyride/Screens/chat/chat.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/database/session_helper.dart';
import 'package:skyride/theme/app_theme.dart';
import 'package:skyride/widgets/shimmer_loading.dart';

class Chat extends StatefulWidget {
  final String sessionKey;

  const Chat({super.key, required this.sessionKey});

  @override
  ChatState createState() => ChatState();
}

class ChatState extends State<Chat> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoading = true;
  String? _error;
  Map<String, dynamic>? currentUser;
  String? currentUserId;
  String userRole = 'user';

  bool get isProvider => userRole == 'machanic' || userRole == 'fuelpump';

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(Chat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionKey != widget.sessionKey) reload();
  }

  Future<void> reload() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final userId = await SessionHelper.getCurrentUserId();
      if (userId == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      currentUserId = userId;
      final user = await SkyRideApi.instance.getUserById(userId);

      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      userRole = user['role'] as String? ?? 'user';

      // Fetch conversations from server
      final conversations = await SkyRideApi.instance.getAllConversations(userId);

      List<Map<String, dynamic>> pending = [];
      if (isProvider) {
        pending = await SkyRideApi.instance.getPendingRequestsForProvider(userId);
      } else {
        pending = await SkyRideApi.instance.getUserPendingRequests(userId);
      }

      if (mounted) {
        setState(() {
          currentUser = Map<String, dynamic>.from(user);
          contacts = conversations;
          pendingRequests = pending;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  IconData _roleIcon(String role) {
    if (role == 'machanic') return Icons.build;
    if (role == 'fuelpump') return Icons.local_gas_station;
    return Icons.person;
  }

  String _formatRole(String role) {
    if (role == 'machanic') return 'Mechanic';
    if (role == 'fuelpump') return 'Fuel Pump';
    return 'User';
  }

  Future<void> _acceptFromChat(Map<String, dynamic> request) async {
    if (currentUserId == null) return;
    final success = await SkyRideApi.instance.acceptRequest(request['id'] as int, currentUserId!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted! You can now chat.')),
      );
      await reload();
    }
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    if (currentUserId == null) return;

    final otherId = user['id'] as String;
    final allowed = await SkyRideApi.instance.canChat(currentUserId!, otherId);
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Send a request from the map and wait for acceptance to start chatting.')),
        );
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          user: SkyRideApi.instance.userToDisplayMap(user),
          currentUserId: currentUserId!,
        ),
      ),
    );
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.chatBackground,
      appBar: AppBar(
        title: const Text("Conversations"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: reload),
        ],
      ),
      body: isLoading
          ? const ShimmerChatList()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading chats', style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: reload, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: reload,
                  color: AppTheme.primary,
                  child: ListView(
                    children: [
                      if (pendingRequests.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            isProvider ? 'Pending Requests' : 'Awaiting Response',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                          ),
                        ),
                        ...pendingRequests.map((req) {
                          final other = isProvider
                              ? req['user'] as Map<String, dynamic>
                              : req['provider'] as Map<String, dynamic>;
                          final role = other['role'] as String? ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            color: Colors.orange.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: Icon(_roleIcon(role), color: Colors.orange),
                              ),
                              title: Text(other['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                isProvider
                                    ? 'Accept to start chat with this user'
                                    : 'Request sent — waiting for ${_formatRole(role)}',
                              ),
                              trailing: isProvider
                                  ? ElevatedButton(
                                      onPressed: () => _acceptFromChat(req),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(70, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: const Text('Accept'),
                                    )
                                  : const Chip(
                                      label: Text('Pending', style: TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.orange,
                                      labelStyle: TextStyle(color: Colors.white),
                                    ),
                            ),
                          );
                        }),
                        const Divider(),
                      ],
                      if (contacts.isEmpty && pendingRequests.isEmpty)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textSecondary),
                                SizedBox(height: 12),
                                Text(
                                  'No conversations yet.\nFind a mechanic or fuel pump on the map to get started.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (contacts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'Active Chats',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                          ),
                        ),
                        ...contacts.map((user) {
                          final role = user['role'] as String? ?? '';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.15),
                                child: Icon(_roleIcon(role), color: AppTheme.primary),
                              ),
                              title: Text(user['username'] as String? ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Phone: ${user['phone']} • ${_formatRole(role)}"),
                                  if (user['lastMessage'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        user['lastMessage'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _openChat(user),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(70, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text("Chat"),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
    );
  }
}
