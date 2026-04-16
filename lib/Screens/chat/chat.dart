// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:url_launcher/url_launcher.dart';
// import './map.dart';
// import './call.dart';
//
// class ChatDetailScreen extends StatefulWidget {
//   final dynamic user;
//
//   ChatDetailScreen({required this.user});
//
//   @override
//   State<ChatDetailScreen> createState() => _ChatDetailScreenState();
// }
//
// class _ChatDetailScreenState extends State<ChatDetailScreen> {
//   final TextEditingController messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   List<dynamic> messages = [];
//   bool isLoading = true;
//   bool isSending = false;
//   final String profileImagePath = 'assets/images/user1.jpg'; // Image path from assets
//
//
//   late String currentUserId;
//   late String receiverId;
//
//   @override
//   void initState() {
//     super.initState();
//     receiverId = widget.user['_id'];
//     loadUserIdAndChat();
//   }
//
//   Future<void> loadUserIdAndChat() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       currentUserId = prefs.getString('userId') ?? '';
//     });
//     fetchChatHistory();
//   }
//
//   Future<void> _launchURL(String url) async {
//     final encodedUrl = Uri.encodeFull(url);
//     final uri = Uri.parse(encodedUrl);
//
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       print('Could not launch $uri');
//     }
//   }
//
//
//
//   Future<void> fetchChatHistory() async {
//     final url = Uri.parse(
//         'https://skyride.onrender.com/api/history?userId=$currentUserId&userId2=$receiverId');
//
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           messages = data['data'];
//           isLoading = false;
//         });
//         scrollToBottom();
//       } else {
//         print("Failed to load chat history: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("Error fetching chat history: $e");
//     }
//   }
//
//   Future<void> sendMessage(String messageText, {double? latitude, double? longitude}) async {
//     final url = Uri.parse('https://skyride.onrender.com/api/send');
//
//     final body = {
//       "senderId": currentUserId,
//       "receiverId": receiverId,
//       "message": messageText,
//       "role": "user",
//       "location": {
//         "latitude": latitude ?? 33.6844,
//         "longitude": longitude ?? 73.0479
//       }
//     };
//
//     final tempMessage = {
//       "senderId": currentUserId,
//       "receiverId": receiverId,
//       "message": messageText,
//     };
//
//     setState(() {
//       isSending = true;
//       messageController.clear();
//       messages.add(tempMessage);
//     });
//
//     scrollToBottom();
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(body),
//       );
//
//       if (response.statusCode != 200) {
//         print("Failed to send message: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("Error sending message: $e");
//     } finally {
//       setState(() {
//         isSending = false;
//       });
//     }
//   }
//
//   Future<Position?> _determinePosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       print('Location services are disabled.');
//       return null;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         print('Location permissions are denied');
//         return null;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       print('Location permissions are permanently denied.');
//       return null;
//     }
//
//     return await Geolocator.getCurrentPosition();
//   }
//
//   void scrollToBottom() {
//     Future.delayed(Duration(milliseconds: 300), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   Widget buildMessageBubble(dynamic msg) {
//     final isMe = msg['senderId'] == currentUserId;
//     final messageText = msg['message'];
//     final isLocation = messageText.toString().startsWith("📍 Shared location:");
//
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         padding: EdgeInsets.all(12),
//         margin: EdgeInsets.symmetric(vertical: 6),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.orange.shade300 : Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: isLocation
//             ? GestureDetector(
//           onTap: () {
//             final url = messageText
//                 .toString()
//                 .replaceFirst("📍 Shared location: ", "")
//                 .trim();
//
//             final uri = Uri.tryParse(url);
//             if (uri != null) {
//               final query = uri.queryParameters['q'];
//               if (query != null) {
//                 final coords = query.split(',');
//                 if (coords.length == 2) {
//                   final lat = double.tryParse(coords[0]);
//                   final lng = double.tryParse(coords[1]);
//
//                   if (lat != null && lng != null) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => ViewLocationScreen(latitude: lat, longitude: lng),
//                       ),
//                     );
//                     return;
//                   }
//                 }
//               }
//             }
//
//             // fallback: open in browser
//             _launchURL(url);
//           },
//
//           child: Text(
//             messageText,
//             style: TextStyle(
//               color: Colors.blueAccent,
//               decoration: TextDecoration.underline,
//             ),
//           ),
//         )
//             : Text(messageText),
//       ),
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => FocusScope.of(context).unfocus(),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(widget.user['username']),
//           backgroundColor: Color(0xFFF25F12),
//           foregroundColor: Colors.black,
//           actions: [
//             IconButton(
//               icon: Icon(Icons.call),
//               onPressed: () {
//                 // Navigate to the audio call screen when the call icon is pressed
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => AudioCallScreen(username: widget.user['username'],profileImagePath: profileImagePath,),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//
//
//         body: Column(
//           children: [
//             Expanded(
//               child: isLoading
//                   ? Center(child: CircularProgressIndicator())
//                   : ListView.builder(
//                 controller: _scrollController,
//                 padding: EdgeInsets.all(16),
//                 itemCount: messages.length,
//                 itemBuilder: (context, index) =>
//                     buildMessageBubble(messages[index]),
//               ),
//             ),
//             Container(
//               padding: EdgeInsets.only(top: 5, bottom: 20, left: 5,right: 5),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 4,
//                     offset: Offset(0, -1),
//                   ),
//                 ],
//               ),
//               child: Row(
//
//
//                 children: [
//
//                   IconButton(
//                     icon: Icon(Icons.location_on, color: Color(0xFFF25F12),size: 35,),
//                     onPressed: () async {
//                       if (!isSending) {
//                         final position = await _determinePosition();
//                         if (position != null) {
//                           final locMessage =
//                               "📍 Shared location: https://maps.google.com/?q=${position.latitude},${position.longitude}";
//                           sendMessage(locMessage,
//                               latitude: position.latitude,
//                               longitude: position.longitude);
//                         }
//                       }
//                     },
//                   ),
//                   Expanded(
//                     child: TextField(
//                       controller: messageController,
//                       textInputAction: TextInputAction.send,
//                       onSubmitted: (value) {
//                         if (value.trim().isNotEmpty && !isSending) {
//                           sendMessage(value.trim());
//                         }
//                       },
//                       decoration: InputDecoration(
//                         hintText: 'Type your message...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 10),
//                       ),
//                     ),
//                   ),
//
//                   isSending
//                       ? SizedBox(
//                     height: 24,
//                     width: 24,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2.5,
//                       valueColor:
//                       AlwaysStoppedAnimation(Color(0xFFF25F12)),
//                     ),
//                   )
//                       : IconButton(
//                     icon: Icon(Icons.send, color: Color(0xFFF25F12), size: 30,),
//                     onPressed: () {
//                       final text = messageController.text.trim();
//                       if (text.isNotEmpty) {
//                         sendMessage(text);
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  ChatDetailScreen({required this.user});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController messageController = TextEditingController();

  // Fake chat messages
  List<Map<String, dynamic>> messages = [
    {"sender": "them", "text": "Hello! How can I help you?"},
    {"sender": "me", "text": "Hi! I need some assistance."},
    {"sender": "them", "text": "Sure, tell me the issue."},
  ];

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "sender": "me",
        "text": messageController.text.trim(),
      });
    });

    messageController.clear();

    // Fake auto reply
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        messages.add({
          "sender": "them",
          "text": "Okay, I will look into it.",
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.user['username']}"),
        backgroundColor: const Color(0xFFF25F12),
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                bool isMe = msg['sender'] == 'me';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.orange[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text']),
                  ),
                );
              },
            ),
          ),

          // Message Box
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  onPressed: sendMessage,
                  icon: Icon(Icons.send, color: Color(0xFFF25F12)),
                  iconSize: 30,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
