import 'package:skyride/database/database_helper.dart';

/// Simulates a live backend — all data access goes through here with network-style delay.
class SkyRideApi {
  static final SkyRideApi instance = SkyRideApi._();
  SkyRideApi._();

  final _db = DatabaseHelper.instance;
  static const Duration _minLatency = Duration(seconds: 1);

  Future<T> _request<T>(Future<T> Function() action) async {
    final stopwatch = Stopwatch()..start();
    final result = await action();
    final remaining = _minLatency.inMilliseconds - stopwatch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }
    return result;
  }

  // Auth & users
  Future<Map<String, dynamic>?> login(String emailOrUsername, String password) =>
      _request(() => _db.login(emailOrUsername, password));

  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    required String dateOfBirth,
    required String country,
    required String phone,
    String role = 'user',
    String? imagePath,
    double? latitude,
    double? longitude,
  }) =>
      _request(() => _db.registerUser(
            username: username,
            email: email,
            password: password,
            dateOfBirth: dateOfBirth,
            country: country,
            phone: phone,
            role: role,
            imagePath: imagePath,
            latitude: latitude,
            longitude: longitude,
          ));

  Future<Map<String, dynamic>?> getUserById(String userId) =>
      _request(() => _db.getUserById(userId));

  Future<Map<String, dynamic>?> getUserByEmail(String email) =>
      _request(() => _db.getUserByEmail(email));

  Future<bool> updateUserLocationSilent(String userId, double latitude, double longitude) =>
      _db.updateUserLocation(userId, latitude, longitude);

  Future<bool> updatePassword(String email, String newPassword) =>
      _request(() => _db.updatePassword(email, newPassword));

  Future<bool> updateUser({
    required String userId,
    required String username,
    required String email,
    required String phone,
    required String role,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) =>
      _request(() => _db.updateUser(
            userId: userId,
            username: username,
            email: email,
            phone: phone,
            role: role,
            imagePath: imagePath,
            latitude: latitude,
            longitude: longitude,
          ));

  Future<bool> updateUserLocation(String userId, double latitude, double longitude) =>
      _request(() => _db.updateUserLocation(userId, latitude, longitude));

  Future<void> deleteAccount(String userId) =>
      _request(() => _db.deleteAccount(userId));

  Future<List<Map<String, dynamic>>> getAllUsersForQuickSwitch() =>
      _request(() => _db.getAllUsersForQuickSwitch());

  // Map & providers
  Future<List<Map<String, dynamic>>> getMechanicsAndFuelPumps() =>
      _request(() => _db.getMechanicsAndFuelPumps());

  Future<void> ensureProvidersNearLocation(double baseLat, double baseLon) =>
      _request(() => _db.ensureProvidersNearLocation(baseLat, baseLon));

  // Service requests
  Future<Map<String, dynamic>?> getRequestBetween(String userId, String providerId) =>
      _request(() => _db.getRequestBetween(userId, providerId));

  Future<int?> createServiceRequest({
    required String userId,
    required String providerId,
    required double userLatitude,
    required double userLongitude,
    String? message,
  }) =>
      _request(() => _db.createServiceRequest(
            userId: userId,
            providerId: providerId,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            message: message,
          ));

  Future<List<Map<String, dynamic>>> getPendingRequestsForProvider(String providerId) =>
      _request(() => _db.getPendingRequestsForProvider(providerId));

  Future<List<Map<String, dynamic>>> getUserPendingRequests(String userId) =>
      _request(() => _db.getUserPendingRequests(userId));

  Future<bool> acceptRequest(int requestId, String providerId) =>
      _request(() => _db.acceptRequest(requestId, providerId));

  Future<bool> rejectRequest(int requestId, String providerId) =>
      _request(() => _db.rejectRequest(requestId, providerId));

  // Chat
  Future<List<Map<String, dynamic>>> getAllConversations(String userId) =>
      _request(() => _db.getAllConversations(userId));

  Future<bool> canChat(String userId1, String userId2) =>
      _request(() => _db.canChat(userId1, userId2));

  Future<int> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    double? latitude,
    double? longitude,
  }) =>
      _request(() => _db.sendMessage(
            senderId: senderId,
            receiverId: receiverId,
            message: message,
            latitude: latitude,
            longitude: longitude,
          ));

  Future<List<Map<String, dynamic>>> getChatHistory(String userId1, String userId2) =>
      _request(() => _db.getChatHistory(userId1, userId2));

  Map<String, dynamic> userToDisplayMap(Map<String, dynamic> user) =>
      _db.userToDisplayMap(user);

  // Settings
  Future<Map<String, dynamic>> getSettings(String userId) =>
      _request(() => _db.getSettings(userId));

  Future<void> updateSettings(String userId, {
    bool? generalNotification,
    bool? sound,
    bool? vibrate,
  }) =>
      _request(() => _db.updateSettings(
            userId,
            generalNotification: generalNotification,
            sound: sound,
            vibrate: vibrate,
          ));

  // AI chat
  Future<void> saveAiMessage(String userId, String role, String text) =>
      _request(() => _db.saveAiMessage(userId, role, text));

  Future<List<Map<String, dynamic>>> getAiChatHistory(String userId) =>
      _request(() => _db.getAiChatHistory(userId));
}
