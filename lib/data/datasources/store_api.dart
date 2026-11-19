import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StoreApi {
  static final instance = StoreApi();
  static const _configuredBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://verve-store-delta.vercel.app',
  );
  Future<Map<String, dynamic>> request(
    String action, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool admin = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in to continue');
    final token = await user.getIdToken();
    final origin = kIsWeb ? Uri.base.origin : _configuredBase;
    final uri = Uri.parse(
      '$origin/api/store',
    ).replace(queryParameters: {'action': action, if (admin) 'admin': 'true'});
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final http.Response response;
    if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
    } else if (method == 'DELETE') {
      response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
    } else {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Store service unavailable. Please try again later.');
    }
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Store request failed');
    }
    return data;
  }
}
