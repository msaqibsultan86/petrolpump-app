import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _pumpsKey = 'pumps_data';
  static const _currentPumpKey = 'current_pump_id';

  // ── Login ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token']);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      await prefs.setString(_pumpsKey, jsonEncode(data['pumps']));

      // Auto-select first pump
      if (data['pumps'] != null && (data['pumps'] as List).isNotEmpty) {
        await prefs.setInt(_currentPumpKey, data['pumps'][0]['id']);
      }

      return data;
    }

    throw Exception(data['error'] ?? 'Login failed');
  }

  // ── Logout ─────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Check Auth ─────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // ── Get Token ──────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── Get User ───────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) return jsonDecode(userData);
    return null;
  }

  // ── Get Pumps ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPumps() async {
    final prefs = await SharedPreferences.getInstance();
    final pumpsData = prefs.getString(_pumpsKey);
    if (pumpsData != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(pumpsData));
    }
    return [];
  }

  // ── Get/Set Current Pump ───────────────────────────────────
  static Future<int> getCurrentPumpId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentPumpKey) ?? 1;
  }

  static Future<void> setCurrentPumpId(int pumpId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentPumpKey, pumpId);
  }

  // ── Get Current Pump Name ──────────────────────────────────
  static Future<String> getCurrentPumpName() async {
    final pumpId = await getCurrentPumpId();
    final pumps = await getPumps();
    for (final p in pumps) {
      if (p['id'] == pumpId) return p['name'] ?? 'Pump $pumpId';
    }
    return 'Pump $pumpId';
  }
}
