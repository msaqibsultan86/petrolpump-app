import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  // ── Authenticated GET request ──────────────────────────────
  static Future<Map<String, dynamic>> get(String url, {Map<String, String>? params}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final pumpId = await AuthService.getCurrentPumpId();
    final queryParams = {
      'pump_id': pumpId.toString(),
      ...?params,
    };

    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 401) {
      await AuthService.logout();
      throw Exception('Session expired. Please login again.');
    }

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Request failed');
    }

    return data;
  }

  // ── Dashboard ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard({String? date}) async {
    return get(ApiConfig.dashboard, params: {
      if (date != null) 'date': date,
    });
  }

  // ── Sales ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getSales({String? from, String? to}) async {
    return get(ApiConfig.sales, params: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
  }

  // ── Purchases ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPurchases({String? from, String? to}) async {
    return get(ApiConfig.purchases, params: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
  }

  // ── Expenses ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getExpenses({String? from, String? to}) async {
    return get(ApiConfig.expenses, params: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
  }

  // ── Loans ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getLoans() async {
    return get(ApiConfig.loans);
  }

  // ── Tanks ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTanks() async {
    return get(ApiConfig.tanks);
  }

  // ── Dip Readings ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getDipReadings({String? from, String? to}) async {
    return get(ApiConfig.dipReadings, params: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
  }

  // ── Day Book ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDaybook({String? from, String? to}) async {
    return get(ApiConfig.daybook, params: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
  }

  // ── Pumps ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPumps() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(Uri.parse(ApiConfig.pumps), headers: {
      'Authorization': 'Bearer $token',
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['pumps']);
    }

    throw Exception(data['error'] ?? 'Failed to load pumps');
  }
}
