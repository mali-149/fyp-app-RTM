import 'package:flutter/material.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/database/session_helper.dart';
import 'package:skyride/theme/app_theme.dart';
import './data.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  bool isTyping = false;
  bool isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final userId = await SessionHelper.getCurrentUserId();
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    _userId = userId;
    final history = await SkyRideApi.instance.getAiChatHistory(userId);
    setState(() {
      messages.clear();
      for (final msg in history) {
        messages.add({
          'role': msg['role'] as String,
          'text': msg['text'] as String,
        });
      }
      isLoading = false;
    });
  }

  Future<void> _saveMessage(String role, String text) async {
    if (_userId != null) {
      await SkyRideApi.instance.saveAiMessage(_userId!, role, text);
    }
  }

  Future<void> typeAIMessage(String fullText) async {
    String currentText = "";

    setState(() {
      messages.add({"role": "ai", "text": ""});
    });

    int index = messages.length - 1;

    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      currentText += fullText[i];
      setState(() => messages[index]["text"] = currentText);
    }

    await _saveMessage('ai', fullText);
  }

  String getResponse(String message) {
    String input = MechanicData.normalize(message);

    for (var key in MechanicData.chatReplies.keys) {
      String cleanKey = MechanicData.normalize(key);
      if (input.contains(cleanKey)) return MechanicData.chatReplies[key]!;
    }

    for (var key in MechanicData.issues.keys) {
      String cleanKey = MechanicData.normalize(key);
      if (input.contains(cleanKey)) {
        var data = MechanicData.issues[key]!;
        String partsText = "";
        for (var p in data["parts"]) {
          partsText += "- ${p["name"]}: ${p["price"]}\n";
        }
        return """
🚗 Problem: ${data["problem"]}

🔧 Cause: ${data["cause"]}

🛠 Solution: ${data["solution"]}

🧾 Parts Needed:
$partsText
""";
      }
    }

    return MechanicData.unknownResponse;
  }

  void sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isTyping = true;
    });

    await _saveMessage('user', text);
    controller.clear();

    await Future.delayed(const Duration(seconds: 1));

    String reply = getResponse(text);
    setState(() => isTyping = false);
    await typeAIMessage(reply);
  }

  Widget buildMessage(Map<String, String> msg) {
    bool isUser = msg["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 18),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Text(
          msg["text"] ?? "",
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardBackground,
      appBar: AppBar(
        title: const Text("Ride to Mechanic AI", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text(
                            "Ask me about your vehicle problems!",
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          itemCount: messages.length + (isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (isTyping && index == messages.length) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text("AI is typing...", style: TextStyle(color: AppTheme.textSecondary)),
                              );
                            }
                            return buildMessage(messages[index]);
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20, top: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: "Ask your vehicle problem...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: sendMessage,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
