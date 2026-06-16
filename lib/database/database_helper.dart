import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:skyride/utils/distance_util.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'skyride.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seedDefaultUsers(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS service_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          user_latitude REAL NOT NULL,
          user_longitude REAL NOT NULL,
          message TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(user_id, provider_id)
        )
      ''');
      await _seedAdditionalProviders(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        date_of_birth TEXT,
        country TEXT,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'user',
        image TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        message TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        user_id TEXT PRIMARY KEY,
        general_notification INTEGER DEFAULT 1,
        sound INTEGER DEFAULT 0,
        vibrate INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE service_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        provider_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        user_latitude REAL NOT NULL,
        user_longitude REAL NOT NULL,
        message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, provider_id)
      )
    ''');
  }

  List<Map<String, dynamic>> _getSeedProviders(String now) {
    // Islamabad area — nearby offsets for testing (~0.3–2 km apart)
    const baseLat = 33.6844;
    const baseLon = 73.0479;

    return [
      {
        'id': 'mech_001',
        'username': 'John Mechanic',
        'email': 'john.mechanic@skyride.com',
        'password': 'mechanic123',
        'date_of_birth': '1985-05-15',
        'country': 'Pakistan',
        'phone': '9876543210',
        'role': 'machanic',
        'image': '',
        'latitude': baseLat + 0.002,
        'longitude': baseLon + 0.003,
        'created_at': now,
      },
      {
        'id': 'fuel_001',
        'username': 'Fuel Pump Raj',
        'email': 'fuel.raj@skyride.com',
        'password': 'fuel123',
        'date_of_birth': '1990-03-20',
        'country': 'Pakistan',
        'phone': '9123456780',
        'role': 'fuelpump',
        'image': '',
        'latitude': baseLat + 0.005,
        'longitude': baseLon + 0.006,
        'created_at': now,
      },
      {
        'id': 'mech_002',
        'username': 'Ali Bike Repair',
        'email': 'ali.bike@skyride.com',
        'password': 'mechanic123',
        'date_of_birth': '1988-08-10',
        'country': 'Pakistan',
        'phone': '9988776655',
        'role': 'machanic',
        'image': '',
        'latitude': baseLat - 0.004,
        'longitude': baseLon - 0.005,
        'created_at': now,
      },
      {
        'id': 'fuel_002',
        'username': 'Shell Station',
        'email': 'shell@skyride.com',
        'password': 'fuel123',
        'date_of_birth': '1992-11-05',
        'country': 'Pakistan',
        'phone': '9112233445',
        'role': 'fuelpump',
        'image': '',
        'latitude': baseLat + 0.008,
        'longitude': baseLon + 0.009,
        'created_at': now,
      },
      {
        'id': 'mech_003',
        'username': 'Quick Fix Garage',
        'email': 'quickfix@skyride.com',
        'password': 'mechanic123',
        'date_of_birth': '1983-02-12',
        'country': 'Pakistan',
        'phone': '3001234567',
        'role': 'machanic',
        'image': '',
        'latitude': baseLat + 0.001,
        'longitude': baseLon - 0.004,
        'created_at': now,
      },
      {
        'id': 'mech_004',
        'username': 'Hassan Auto',
        'email': 'hassan.auto@skyride.com',
        'password': 'mechanic123',
        'date_of_birth': '1987-07-22',
        'country': 'Pakistan',
        'phone': '3012345678',
        'role': 'machanic',
        'image': '',
        'latitude': baseLat - 0.006,
        'longitude': baseLon + 0.002,
        'created_at': now,
      },
      {
        'id': 'mech_005',
        'username': 'Roadside Rescue',
        'email': 'rescue@skyride.com',
        'password': 'mechanic123',
        'date_of_birth': '1991-11-30',
        'country': 'Pakistan',
        'phone': '3023456789',
        'role': 'machanic',
        'image': '',
        'latitude': baseLat + 0.003,
        'longitude': baseLon - 0.007,
        'created_at': now,
      },
      {
        'id': 'fuel_003',
        'username': 'PSO Pump',
        'email': 'pso@skyride.com',
        'password': 'fuel123',
        'date_of_birth': '1989-04-18',
        'country': 'Pakistan',
        'phone': '3034567890',
        'role': 'fuelpump',
        'image': '',
        'latitude': baseLat - 0.003,
        'longitude': baseLon + 0.007,
        'created_at': now,
      },
      {
        'id': 'fuel_004',
        'username': 'Total Fuel',
        'email': 'total@skyride.com',
        'password': 'fuel123',
        'date_of_birth': '1993-09-08',
        'country': 'Pakistan',
        'phone': '3045678901',
        'role': 'fuelpump',
        'image': '',
        'latitude': baseLat + 0.007,
        'longitude': baseLon - 0.003,
        'created_at': now,
      },
      {
        'id': 'fuel_005',
        'username': 'Caltex Station',
        'email': 'caltex@skyride.com',
        'password': 'fuel123',
        'date_of_birth': '1994-12-25',
        'country': 'Pakistan',
        'phone': '3056789012',
        'role': 'fuelpump',
        'image': '',
        'latitude': baseLat - 0.008,
        'longitude': baseLon - 0.004,
        'created_at': now,
      },
    ];
  }

  Future<void> _seedDefaultUsers(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final user in _getSeedProviders(now)) {
      await db.insert('users', user);
    }
  }

  Future<void> _seedAdditionalProviders(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final user in _getSeedProviders(now)) {
      final existing = await db.query('users', where: 'id = ?', whereArgs: [user['id']], limit: 1);
      if (existing.isEmpty) {
        await db.insert('users', user);
      }
    }
  }

  String _generateId() => 'user_${DateTime.now().millisecondsSinceEpoch}';

  // ─── User Operations ───────────────────────────────────────────────

  Future<Map<String, dynamic>?> login(String emailOrUsername, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'password = ? AND (email = ? OR username = ?)',
      whereArgs: [password, emailOrUsername, emailOrUsername],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

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
  }) async {
    final db = await database;

    final existing = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (existing.isNotEmpty) return null;

    final id = _generateId();
    await db.insert('users', {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'date_of_birth': dateOfBirth,
      'country': country,
      'phone': phone,
      'role': role,
      'image': imagePath ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('settings', {
      'user_id': id,
      'general_notification': 1,
      'sound': 0,
      'vibrate': 1,
    });

    return id;
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<List<Map<String, dynamic>>> getMechanicsAndFuelPumps() async {
    final db = await database;
    return db.query('users', where: "role IN ('machanic', 'fuelpump')");
  }

  Future<List<Map<String, dynamic>>> getRegularUsers() async {
    final db = await database;
    return db.query('users', where: "role = 'user'");
  }

  Future<List<Map<String, dynamic>>> getChatContactsForRole(String role, String currentUserId) async {
    if (role == 'user') {
      return getAcceptedProvidersForUser(currentUserId);
    } else if (role == 'fuelpump' || role == 'machanic') {
      return getAcceptedUsersForProvider(currentUserId);
    }
    return [];
  }

  Future<bool> updateUser({
    required String userId,
    required String username,
    required String email,
    required String phone,
    required String role,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    final count = await db.update(
      'users',
      {
        'username': username,
        'email': email,
        'phone': phone,
        'role': role,
        if (imagePath != null) 'image': imagePath,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  Future<bool> updateUserLocation(String userId, double latitude, double longitude) async {
    final db = await database;
    final count = await db.update(
      'users',
      {'latitude': latitude, 'longitude': longitude},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  Future<bool> updatePassword(String email, String newPassword) async {
    final db = await database;
    final count = await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
    return count > 0;
  }

  Future<void> deleteAccount(String userId) async {
    final db = await database;
    await db.delete('service_requests', where: 'user_id = ? OR provider_id = ?', whereArgs: [userId, userId]);
    await db.delete('messages', where: 'sender_id = ? OR receiver_id = ?', whereArgs: [userId, userId]);
    await db.delete('ai_chat_messages', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('settings', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> ensureProvidersNearLocation(double baseLat, double baseLon) async {
    final db = await database;
    // Spread providers between ~2 km and ~48 km (within 50 km search range).
    final placements = [
      {'id': 'mech_001', 'km': 2.0, 'bearing': 25.0},
      {'id': 'fuel_001', 'km': 6.5, 'bearing': 80.0},
      {'id': 'mech_002', 'km': 11.0, 'bearing': 145.0},
      {'id': 'fuel_002', 'km': 16.5, 'bearing': 210.0},
      {'id': 'mech_003', 'km': 22.0, 'bearing': 300.0},
      {'id': 'mech_004', 'km': 28.0, 'bearing': 55.0},
      {'id': 'mech_005', 'km': 34.0, 'bearing': 125.0},
      {'id': 'fuel_003', 'km': 39.5, 'bearing': 195.0},
      {'id': 'fuel_004', 'km': 44.0, 'bearing': 270.0},
      {'id': 'fuel_005', 'km': 48.0, 'bearing': 340.0},
    ];

    for (final p in placements) {
      final point = DistanceUtil.offsetByKmAndBearing(
        baseLat,
        baseLon,
        p['km'] as double,
        p['bearing'] as double,
      );
      await db.update(
        'users',
        {
          'latitude': point.latitude,
          'longitude': point.longitude,
        },
        where: 'id = ?',
        whereArgs: [p['id']],
      );
    }
  }

  // ─── Service Request Operations ────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllUsersForQuickSwitch() async {
    final db = await database;
    return db.query('users', orderBy: 'role ASC, username ASC');
  }

  Future<bool> canChat(String userId1, String userId2) async {
    final db = await database;
    final accepted = await db.query(
      'service_requests',
      where: "status = 'accepted' AND ((user_id = ? AND provider_id = ?) OR (user_id = ? AND provider_id = ?))",
      whereArgs: [userId1, userId2, userId2, userId1],
      limit: 1,
    );
    if (accepted.isNotEmpty) return true;

    final messages = await getChatHistory(userId1, userId2);
    return messages.isNotEmpty;
  }

  Future<String?> getLastMessageTime(String userId1, String userId2) async {
    final messages = await getChatHistory(userId1, userId2);
    if (messages.isEmpty) return null;
    return messages.last['created_at'] as String?;
  }

  /// All conversation partners from message history and active service links.
  Future<List<Map<String, dynamic>>> getAllConversations(String userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT partner_id FROM (
        SELECT receiver_id AS partner_id FROM messages WHERE sender_id = ?
        UNION
        SELECT sender_id AS partner_id FROM messages WHERE receiver_id = ?
      )
    ''', [userId, userId]);

    final partnerIds = <String>{};
    for (final r in rows) {
      final id = r['partner_id'] as String?;
      if (id != null && id != userId) partnerIds.add(id);
    }

    final user = await getUserById(userId);
    final role = user?['role'] as String? ?? 'user';
    if (role == 'user') {
      for (final p in await getAcceptedProvidersForUser(userId)) {
        partnerIds.add(p['id'] as String);
      }
    } else if (role == 'machanic' || role == 'fuelpump') {
      for (final u in await getAcceptedUsersForProvider(userId)) {
        partnerIds.add(u['id'] as String);
      }
    }

    final conversations = <Map<String, dynamic>>[];
    for (final partnerId in partnerIds) {
      final partner = await getUserById(partnerId);
      if (partner == null) continue;

      final entry = Map<String, dynamic>.from(partner);
      entry['lastMessage'] = await getLastMessagePreview(userId, partnerId);
      entry['lastMessageTime'] = await getLastMessageTime(userId, partnerId);
      conversations.add(entry);
    }

    conversations.sort((a, b) {
      final at = a['lastMessageTime'] as String? ?? '';
      final bt = b['lastMessageTime'] as String? ?? '';
      return bt.compareTo(at);
    });

    return conversations;
  }

  Map<String, dynamic> mutableRow(Map<String, dynamic> row) => Map<String, dynamic>.from(row);

  Future<Map<String, dynamic>?> getRequestBetween(String userId, String providerId) async {
    final db = await database;
    final results = await db.query(
      'service_requests',
      where: 'user_id = ? AND provider_id = ?',
      whereArgs: [userId, providerId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int?> createServiceRequest({
    required String userId,
    required String providerId,
    required double userLatitude,
    required double userLongitude,
    String? message,
  }) async {
    final db = await database;
    final existing = await getRequestBetween(userId, providerId);

    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      if (existing['status'] == 'pending' || existing['status'] == 'accepted') {
        return null;
      }
      await db.update(
        'service_requests',
        {
          'status': 'pending',
          'user_latitude': userLatitude,
          'user_longitude': userLongitude,
          'message': message ?? 'Service request',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
      return existing['id'] as int;
    }

    return db.insert('service_requests', {
      'user_id': userId,
      'provider_id': providerId,
      'status': 'pending',
      'user_latitude': userLatitude,
      'user_longitude': userLongitude,
      'message': message ?? 'Service request',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingRequestsForProvider(String providerId) async {
    final db = await database;
    final requests = await db.query(
      'service_requests',
      where: "provider_id = ? AND status = 'pending'",
      whereArgs: [providerId],
      orderBy: 'created_at DESC',
    );

    final List<Map<String, dynamic>> result = [];
    for (final req in requests) {
      final user = await getUserById(req['user_id'] as String);
      if (user != null) {
        result.add({...Map<String, dynamic>.from(req), 'user': Map<String, dynamic>.from(user)});
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getUserPendingRequests(String userId) async {
    final db = await database;
    final requests = await db.query(
      'service_requests',
      where: "user_id = ? AND status = 'pending'",
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    final List<Map<String, dynamic>> result = [];
    for (final req in requests) {
      final provider = await getUserById(req['provider_id'] as String);
      if (provider != null) {
        result.add({...Map<String, dynamic>.from(req), 'provider': Map<String, dynamic>.from(provider)});
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getAcceptedProvidersForUser(String userId) async {
    final db = await database;
    final requests = await db.query(
      'service_requests',
      where: "user_id = ? AND status = 'accepted'",
      whereArgs: [userId],
    );

    final List<Map<String, dynamic>> result = [];
    for (final req in requests) {
      final provider = await getUserById(req['provider_id'] as String);
      if (provider != null) result.add(provider);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getAcceptedUsersForProvider(String providerId) async {
    final db = await database;
    final requests = await db.query(
      'service_requests',
      where: "provider_id = ? AND status = 'accepted'",
      whereArgs: [providerId],
    );

    final List<Map<String, dynamic>> result = [];
    for (final req in requests) {
      final user = await getUserById(req['user_id'] as String);
      if (user != null) result.add(user);
    }
    return result;
  }

  Future<bool> acceptRequest(int requestId, String providerId) async {
    final db = await database;
    final requests = await db.query(
      'service_requests',
      where: 'id = ? AND provider_id = ?',
      whereArgs: [requestId, providerId],
      limit: 1,
    );
    if (requests.isEmpty) return false;

    final req = requests.first;
    final userId = req['user_id'] as String;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'service_requests',
      {'status': 'accepted', 'updated_at': now},
      where: 'id = ?',
      whereArgs: [requestId],
    );

    final provider = await getUserById(providerId);
    final providerName = provider?['username'] ?? 'Provider';
    final role = provider?['role'] as String? ?? '';

    final welcomeMsg = role == 'fuelpump'
        ? "Hello! $providerName here. Your fuel request has been accepted. How can we help?"
        : "Hello! $providerName here. Your service request has been accepted. Please describe your issue.";

    await sendMessage(senderId: providerId, receiverId: userId, message: welcomeMsg);
    return true;
  }

  Future<bool> rejectRequest(int requestId, String providerId) async {
    final db = await database;
    final count = await db.update(
      'service_requests',
      {'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND provider_id = ? AND status = ?',
      whereArgs: [requestId, providerId, 'pending'],
    );
    return count > 0;
  }

  // ─── Message Operations ────────────────────────────────────────────

  Future<int> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    return db.insert('messages', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String userId1, String userId2) async {
    final db = await database;
    return db.query(
      'messages',
      where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
      orderBy: 'created_at ASC',
    );
  }

  Future<String?> getLastMessagePreview(String currentUserId, String otherUserId) async {
    final messages = await getChatHistory(currentUserId, otherUserId);
    if (messages.isEmpty) return null;
    return messages.last['message'] as String?;
  }

  // ─── Settings Operations ───────────────────────────────────────────

  Future<Map<String, dynamic>> getSettings(String userId) async {
    final db = await database;
    final results = await db.query('settings', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (results.isEmpty) {
      await db.insert('settings', {
        'user_id': userId,
        'general_notification': 1,
        'sound': 0,
        'vibrate': 1,
      });
      return {'general_notification': 1, 'sound': 0, 'vibrate': 1};
    }
    return results.first;
  }

  Future<void> updateSettings(String userId, {
    bool? generalNotification,
    bool? sound,
    bool? vibrate,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (generalNotification != null) updates['general_notification'] = generalNotification ? 1 : 0;
    if (sound != null) updates['sound'] = sound ? 1 : 0;
    if (vibrate != null) updates['vibrate'] = vibrate ? 1 : 0;

    if (updates.isNotEmpty) {
      await db.update('settings', updates, where: 'user_id = ?', whereArgs: [userId]);
    }
  }

  // ─── AI Chat Operations ────────────────────────────────────────────

  Future<void> saveAiMessage(String userId, String role, String text) async {
    final db = await database;
    await db.insert('ai_chat_messages', {
      'user_id': userId,
      'role': role,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAiChatHistory(String userId) async {
    final db = await database;
    return db.query(
      'ai_chat_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> clearAiChatHistory(String userId) async {
    final db = await database;
    await db.delete('ai_chat_messages', where: 'user_id = ?', whereArgs: [userId]);
  }

  Map<String, dynamic> userToDisplayMap(Map<String, dynamic> user) {
    return {
      '_id': user['id'],
      'userId': user['id'],
      'username': user['username'],
      'email': user['email'],
      'phone': user['phone'],
      'date_of_birth': user['date_of_birth'],
      'country': user['country'],
      'role': user['role'],
      'image': user['image'],
      'location': user['latitude'] != null
          ? {
              'type': 'Point',
              'coordinates': [user['longitude'], user['latitude']],
            }
          : null,
    };
  }
}
