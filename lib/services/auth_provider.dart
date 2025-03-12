import 'package:flutter/material.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../models/absensi.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  late EncryptedSharedPreferences _storage;
  bool _isInitialized = false;
  List<Absensi> _absensiList = [];
  int _totalPages = 1;

  AuthProvider() {
    _initStorage();
  }

  User? get user => _user;
  List<Absensi> get absensiList => _absensiList;
  int get totalPages => _totalPages;

  Future<void> _initStorage() async {
    await EncryptedSharedPreferences.initialize('mySecretKey12345');
    _storage = EncryptedSharedPreferences.getInstance();
    _isInitialized = true;
    await loadUser();
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    if (!_isInitialized) await _initStorage();
    _user = user;
    await _storage.setString('id', user.id.toString(), notify: false);
    await _storage.setString('email', user.email, notify: false);
    await _storage.setString('role', user.role, notify: false);
    await _storage.setString('token', user.token, notify: false);
    await _storage.setString('refresh_token', user.refreshToken, notify: false);
    print(
      'User saved - ID: ${user.id}, Token: ${user.token}, Refresh: ${user.refreshToken}',
    );
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    if (!_isInitialized) await _initStorage();
    if (_user?.refreshToken == null) return false;

    final url = Uri.parse('http://10.0.2.2/api_kehadiranmu/auth/refresh');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _user!.refreshToken}),
      );

      final data = jsonDecode(response.body);
      print(
        'Refresh Token Response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        _user = User(
          id: _user!.id,
          email: _user!.email,
          role: _user!.role,
          token: data['access_token'],
          refreshToken: _user!.refreshToken,
        );
        await _storage.setString('token', _user!.token, notify: false);
        print('New Token saved: ${_user!.token}');
        notifyListeners();
        return true;
      } else {
        print('Refresh failed: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  Future<User?> loadUser() async {
    if (!_isInitialized) await _initStorage();
    print('Starting loadUser...');
    try {
      final id = _storage.getString('id');
      final email = _storage.getString('email');
      final role = _storage.getString('role');
      final token = _storage.getString('token');
      final refreshToken = _storage.getString('refresh_token');

      print(
        'LoadUser - ID: $id, Email: $email, Role: $role, Token: $token, Refresh: $refreshToken',
      );
      if (id != null &&
          email != null &&
          role != null &&
          token != null &&
          refreshToken != null) {
        _user = User(
          id: int.parse(id),
          email: email,
          role: role,
          token: token,
          refreshToken: refreshToken,
        );
        print('User loaded: ${_user!.role}, Token: ${_user!.token}');
      } else {
        print('No complete user data found');
        _user = null;
      }
      notifyListeners();
      return _user;
    } catch (e) {
      print('Error loading user: $e');
      _user = null;
      return null;
    }
  }

  Future<void> logout() async {
    if (!_isInitialized) await _initStorage();
    _user = null;
    _absensiList = [];
    await _storage.clear(notify: false);
    notifyListeners();
  }

  Future<bool> fetchAbsensi({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    if (!_isInitialized) await _initStorage();
    if (_user?.token == null) return false;

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
    final url = Uri.parse(
      'http://10.0.2.2/api_kehadiranmu/absensi',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      print(
        'Fetch Absensi Response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data'];
        final newItems = data.map((item) => Absensi.fromJson(item)).toList();
        if (page == 1) {
          _absensiList = newItems; // Reset list untuk page 1
        } else {
          _absensiList.addAll(newItems); // Tambah untuk infinite scroll
        }
        _totalPages = jsonData['pages'];
        print(
          'Parsed Absensi List Length: ${_absensiList.length}, Total Pages: $_totalPages',
        );
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await fetchAbsensi(
            page: page,
            limit: limit,
            startDate: startDate,
            endDate: endDate,
          );
        } else {
          return false;
        }
      } else {
        print('Fetch failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error fetching absensi: $e');
      return false;
    }
  }

  Future<bool> fetchAllAbsensi({
    int page = 1,
    int limit = 10,
    String? tanggalAwal,
    String? tanggalAkhir,
    String? shift,
    String? userId,
    String? statusTelat,
  }) async {
    if (!_isInitialized) await _initStorage();
    if (_user?.token == null) return false;

    if (_user!.role != 'admin') {
      print('Access denied: User is not admin');
      return false;
    }

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (tanggalAwal != null) 'tanggal_awal': tanggalAwal,
      if (tanggalAkhir != null) 'tanggal_akhir': tanggalAkhir,
      if (shift != null) 'shift': shift,
      if (userId != null) 'user_id': userId,
      if (statusTelat != null) 'status_telat': statusTelat,
    };
    final url = Uri.parse(
      'http://10.0.2.2/api_kehadiranmu/admin/absensi',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      print(
        'Fetch All Absensi Response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data'];
        final newItems = data.map((item) => Absensi.fromJson(item)).toList();
        if (page == 1) {
          _absensiList = newItems; // Reset untuk page 1
        } else {
          _absensiList.addAll(newItems); // Tambah untuk infinite scroll
        }
        _totalPages = jsonData['total_pages'];
        print(
          'Parsed Absensi List Length: ${_absensiList.length}, Total Pages: $_totalPages',
        );
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await fetchAllAbsensi(
            page: page,
            limit: limit,
            tanggalAwal: tanggalAwal,
            tanggalAkhir: tanggalAkhir,
            shift: shift,
            userId: userId,
            statusTelat: statusTelat,
          );
        }
        return false;
      } else if (response.statusCode == 403) {
        print('Access denied: Not an admin');
        return false;
      } else {
        print('Fetch failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error fetching absensi: $e');
      return false;
    }
  }
}
