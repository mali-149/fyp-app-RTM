// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:skyride/Screens/chat/chat.dart';
//
// class Chat extends StatefulWidget {
//   @override
//   State<Chat> createState() => _ChatState();
// }
//
// class _ChatState extends State<Chat> {
//   List<dynamic> users = [];
//   bool isLoading = true;
//   Map<String, dynamic>? currentUser;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchCurrentUserAndLoadUsers();
//   }
//
//   Future<void> fetchCurrentUserAndLoadUsers() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('userId') ?? '';
//
//     if (userId.isEmpty) {
//       setState(() {
//         isLoading = false;
//       });
//       return;
//     }
//
//     final url = Uri.parse('https://skyride.onrender.com/api/getaccount/$userId');
//
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         if (jsonData['success'] == true) {
//           currentUser = jsonData['data'];
//           fetchUsersBasedOnRole(currentUser!['role']);
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       print("User fetch error: $e");
//       setState(() => isLoading = false);
//     }
//   }
//
//   Future<void> fetchUsersBasedOnRole(String role) async {
//     Uri url;
//
//     if (role == 'user') {
//       url = Uri.parse('https://skyride.onrender.com/api/getmechanicfuel');
//     } else if (role == 'fuelpump' || role == 'machanic') {
//       url = Uri.parse('https://skyride.onrender.com/api/getuser');
//     } else {
//       setState(() {
//         isLoading = false;
//         users = [];
//       });
//       return;
//     }
//
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         setState(() {
//           users = jsonData['users'];
//           isLoading = false;
//         });
//       } else {
//         print("Failed to load users: ${response.statusCode}");
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       print("Fetch users error: $e");
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFE3F2FD),
//       appBar: AppBar(
//         title: const Text("Conversions"),
//         centerTitle: true,
//         backgroundColor: Color(0xFFF25F12),
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : users.isEmpty
//           ? Center(child: Text("No users found."))
//           : ListView.builder(
//         itemCount: users.length,
//         itemBuilder: (context, index) {
//           final user = users[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//             child: ListTile(
//               leading: Icon(Icons.person, color: Color(0xFFF25F12)),
//               title: Text(user['username'] ?? 'No Name'),
//               subtitle: Text("Phone: ${user['phone']} \n${user['role']}"),
//               trailing: ElevatedButton(
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text("Start chat with ${user['username']}"),
//                     ),
//                   );
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ChatDetailScreen(user: user),
//                     ),
//                   );
//                 },
//                 child: Text("Chat"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFFF25F12),
//                   foregroundColor: Colors.black,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:skyride/Screens/chat/chat.dart';
// import 'package:skyride/Screens/chat/chat_detail.dart';

class Chat extends StatefulWidget {
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  bool isLoading = false;

  // Fake Logged-in User
  Map<String, dynamic> currentUser = {
    "userId": "001",
    "username": "Test User",
    "role": "user",
  };

  // Fake Chat Users
  List<Map<String, dynamic>> users = [
    {
      "userId": "101",
      "username": "John Mechanic",
      "phone": "9876543210",
      "role": "mechanic",
    },
    {
      "userId": "102",
      "username": "Fuel Pump Raj",
      "phone": "9123456780",
      "role": "fuelpump",
    },
    {
      "userId": "103",
      "username": "Alex User",
      "phone": "9988776655",
      "role": "user",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text("Conversations"),
        centerTitle: true,
        backgroundColor: const Color(0xFFF25F12),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFF25F12)),
              title: Text(user['username']),
              subtitle: Text(
                "Phone: ${user['phone']}\nRole: ${user['role']}",
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(user: user),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF25F12),
                  foregroundColor: Colors.black,
                ),
                child: const Text("Chat"),
              ),
            ),
          );
        },
      ),
    );
  }
}
