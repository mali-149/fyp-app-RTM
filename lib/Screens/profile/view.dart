import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/database/session_helper.dart';
import 'package:skyride/theme/app_theme.dart';
import 'package:skyride/widgets/shimmer_loading.dart';

const String cameraIcon = '''
<svg viewBox="0 0 24 24">
  <path fill="black" d="M12 5c-3.86 0-7 3.14-7 7s3.14 7 7 7
  7-3.14 7-7-3.14-7-7-7zm0 12c-2.76 0-5-2.24-5-5s2.24-5
  5-5 5 2.24 5 5-2.24 5-5 5zm8-14h-3.17l-1.84-2H8.01L6.17
  3H3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h18c1.1 0 2-.9
  2-2V5c0-1.1-.9-2-2-2z"/>
</svg>
''';

class ViewAccountScreen extends StatefulWidget {
  const ViewAccountScreen({super.key});

  @override
  State<ViewAccountScreen> createState() => _ViewAccountScreenState();
}

class _ViewAccountScreenState extends State<ViewAccountScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userId = await SessionHelper.getCurrentUserId();
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in.';
      });
      return;
    }

    try {
      final user = await SkyRideApi.instance.getUserById(userId);
      setState(() {
        _user = user;
        _isLoading = false;
        _error = user == null ? 'User data not found.' : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.screenBackground,
      appBar: AppBar(title: const Text("My Account")),
      body: _isLoading
          ? const ShimmerProfileView()
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _user == null
                  ? const Center(child: Text('No user data found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: ProfilePic(imagePath: _user!['image'] as String?),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              buildStyledInfoTile("Username", _user!['username'] ?? ''),
                              buildStyledInfoTile("Email", _user!['email'] ?? ''),
                              buildStyledInfoTile("Phone", _user!['phone']?.toString() ?? ''),
                              buildStyledInfoTile("Date of Birth", _user!['date_of_birth'] ?? ''),
                              buildStyledInfoTile("Country", _user!['country'] ?? ''),
                              buildStyledInfoTile("Role", _formatRole(_user!['role'] ?? '')),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'machanic':
        return 'Mechanic';
      case 'fuelpump':
        return 'Fuel Pump';
      case 'user':
        return 'User';
      default:
        return role;
    }
  }
}

Widget buildStyledInfoTile(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const Divider(height: 20, thickness: 0.4),
      ],
    ),
  );
}

class ProfilePic extends StatelessWidget {
  final String? imagePath;

  const ProfilePic({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    ImageProvider image;
    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('/') || imagePath!.contains(':\\')) {
        image = FileImage(File(imagePath!));
      } else {
        image = NetworkImage(imagePath!);
      }
    } else {
      image = const AssetImage("assets/images/user1.jpg");
    }

    return SizedBox(
      height: 125,
      width: 125,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(radius: 60, backgroundImage: image),
          Positioned(
            bottom: -5,
            right: -5,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
              ),
              child: IconButton(
                icon: SvgPicture.string(cameraIcon),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
