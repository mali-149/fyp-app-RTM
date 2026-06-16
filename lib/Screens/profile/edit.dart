import 'dart:io';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/database/session_helper.dart';
import 'package:skyride/theme/app_theme.dart';
import 'package:skyride/widgets/shimmer_loading.dart';

class UpdateAccountScreen extends StatefulWidget {
  const UpdateAccountScreen({super.key});

  @override
  State<UpdateAccountScreen> createState() => _UpdateAccountScreenState();
}

class _UpdateAccountScreenState extends State<UpdateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _userId;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _role = 'user';

  File? _imageFile;
  final List<String> _roles = ['machanic', 'fuelpump', 'user'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userId = await SessionHelper.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = userId;

    try {
      final user = await SkyRideApi.instance.getUserById(userId);
      if (user != null) {
        _user = user;
        _usernameController.text = user['username'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone']?.toString() ?? '';
        _role = user['role'] ?? 'user';
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() => _isLoading = true);

    double? lat;
    double? lon;

    try {
      final location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await location.requestService();

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }

      if (permission == PermissionStatus.granted || permission == PermissionStatus.grantedLimited) {
        final locData = await location.getLocation();
        if (locData.latitude != null && locData.longitude != null) {
          lat = locData.latitude;
          lon = locData.longitude;
        }
      }
    } catch (_) {}

    try {
      final success = await SkyRideApi.instance.updateUser(
        userId: _userId!,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        imagePath: _imageFile?.path,
        latitude: lat,
        longitude: lon,
      );

      if (success) {
        final updatedUser = await SkyRideApi.instance.getUserById(_userId!);
        if (updatedUser != null) await SessionHelper.saveUserSession(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account updated successfully!")),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider _getImageProvider(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('/') || imagePath.contains(':\\')) {
        return FileImage(File(imagePath));
      }
      return NetworkImage(imagePath);
    }
    return const AssetImage('assets/images/user1.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _user?['image'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.screenBackground,
      appBar: AppBar(title: const Text("Update Account")),
      body: _isLoading && _user == null
          ? const ShimmerFormLoading()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : _getImageProvider(imagePath),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: SvgPicture.string(cameraIcon),
                              onPressed: _pickImage,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField("Username", _usernameController),
                      _buildTextField("Email", _emailController, keyboard: TextInputType.emailAddress),
                      _buildTextField("Phone", _phoneController, keyboard: TextInputType.phone),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role == 'machanic' ? 'Mechanic' : role == 'fuelpump' ? 'Fuel Pump' : 'User'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _role = value!),
                        decoration: const InputDecoration(labelText: "Role"),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateAccount,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Update Account"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}

const String cameraIcon = '''
<svg viewBox="0 0 24 24">
  <path fill="black" d="M12 5c-3.86 0-7 3.14-7 7s3.14 7 7 7
  7-3.14 7-7-3.14-7-7-7zm0 12c-2.76 0-5-2.24-5-5s2.24-5
  5-5 5 2.24 5 5-2.24 5-5 5zm8-14h-3.17l-1.84-2H8.01L6.17
  3H3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h18c1.1 0 2-.9
  2-2V5c0-1.1-.9-2-2-2z"/>
</svg>
''';
