import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyride/services/skyride_api.dart';

class SessionHelper {
  static final _api = SkyRideApi.instance;

  static Future<void> saveUserSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', 'session_${user['id']}');
    await prefs.setString('userId', user['id'] as String);
    await prefs.setString('username', user['username'] as String? ?? '');
    await prefs.setString('email', user['email'] as String? ?? '');
    await prefs.setString('dob', user['date_of_birth'] as String? ?? '');
    await prefs.setString('phone', user['phone']?.toString() ?? '');
    await prefs.setString('country', user['country'] as String? ?? '');
    await prefs.setString('role', user['role'] as String? ?? 'user');
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;
    return _api.getUserById(userId);
  }

  static Future<bool> switchAccount(String email, String password) async {
    final user = await _api.login(email, password);
    if (user == null) return false;
    await saveUserSession(user);
    return true;
  }

  static Future<List<Map<String, dynamic>>> getQuickSwitchAccounts() async {
    return _api.getAllUsersForQuickSwitch();
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
