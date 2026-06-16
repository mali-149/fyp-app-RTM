import 'package:flutter/material.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/database/session_helper.dart';
import 'package:skyride/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool generalNotification = true;
  bool sound = false;
  bool vibrate = true;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = await SessionHelper.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = userId;
    final settings = await SkyRideApi.instance.getSettings(userId);
    setState(() {
      generalNotification = (settings['general_notification'] ?? 1) == 1;
      sound = (settings['sound'] ?? 0) == 1;
      vibrate = (settings['vibrate'] ?? 1) == 1;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_userId == null) return;
    await SkyRideApi.instance.updateSettings(
      _userId!,
      generalNotification: generalNotification,
      sound: sound,
      vibrate: vibrate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 10, bottom: 10),
                  child: Text(
                    "Common Settings",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: AppTheme.primary),
                  ),
                ),
                _buildSwitchTile(
                  title: "General Notifications",
                  value: generalNotification,
                  onChanged: (val) {
                    setState(() => generalNotification = val);
                    _saveSettings();
                  },
                ),
                _buildSwitchTile(
                  title: "Sound",
                  value: sound,
                  onChanged: (val) {
                    setState(() => sound = val);
                    _saveSettings();
                  },
                ),
                _buildSwitchTile(
                  title: "Vibration",
                  value: vibrate,
                  onChanged: (val) {
                    setState(() => vibrate = val);
                    _saveSettings();
                  },
                ),
                const Divider(),
              ],
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15)),
      value: value,
      onChanged: onChanged,
    );
  }
}
