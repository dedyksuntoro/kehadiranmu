import 'package:flutter/material.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../models/absensi.dart';
import '../models/shift.dart';
import '../models/lokasi.dart';
import '../models/user_all.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  late EncryptedSharedPreferences _storage;
  bool _isInitialized = false;
  List<Absensi> _absensiList = [];
  int _totalPages = 1;
  List<Shift> _shiftList = [];
  List<Lokasi> _lokasiList = [];
  List<UserAll> _userList = [];

  AuthProvider() {
    _initStorage();
  }

  User? get user => _user;
  List<Absensi> get absensiList => _absensiList;
  int get totalPages => _totalPages;
  List<Shift> get shiftList => _shiftList;
  List<Lokasi> get lokasiList => _lokasiList;
  List<UserAll> get userList => _userList;

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
    await _storage.setString('id', user.id, notify: false); // Sudah String
    await _storage.setString('nama', user.nama, notify: false);
    await _storage.setString('email', user.email, notify: false);
    await _storage.setString('role', user.role, notify: false);
    await _storage.setString('token', user.token, notify: false);
    if (user.refreshToken != null) {
      await _storage.setString(
        'refresh_token',
        user.refreshToken!,
        notify: false,
      );
    }
    print(
      'User saved - ID: ${user.id}, Email: ${user.email}, Role: ${user.role}, Token: ${user.token}, Refresh: ${user.refreshToken}',
    );
    notifyListeners();
  }

  Future<bool> fetchLokasi() async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/lokasi',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      print('Fetch Lokasi Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _lokasiList = data.map((item) => Lokasi.fromJson(item)).toList();
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await fetchLokasi();
        }
        return false;
      } else {
        print('Fetch lokasi failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error fetching lokasi: $e');
      return false;
    }
  }

  Future<bool> createLokasi(
    String namaLokasi,
    double latitude,
    double longitude,
    int radius,
  ) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/lokasi',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
        body: jsonEncode({
          'nama_lokasi': namaLokasi,
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        }),
      );

      print(
        'Create Lokasi Response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 201) {
        await fetchLokasi(); // Refresh daftar lokasi
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await createLokasi(namaLokasi, latitude, longitude, radius);
        }
        return false;
      } else {
        print('Create lokasi failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error creating lokasi: $e');
      return false;
    }
  }

  Future<bool> updateLokasi(
    int id,
    String namaLokasi,
    double latitude,
    double longitude,
    int radius,
  ) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/lokasi/$id',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
        body: jsonEncode({
          'nama_lokasi': namaLokasi,
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        }),
      );

      print(
        'Update Lokasi Response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        await fetchLokasi(); // Refresh daftar lokasi
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await updateLokasi(
            id,
            namaLokasi,
            latitude,
            longitude,
            radius,
          );
        }
        return false;
      } else {
        print('Update lokasi failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating lokasi: $e');
      return false;
    }
  }

  Future<bool> deleteLokasi(int id) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/lokasi/$id',
    );
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      print(
        'Delete Lokasi Response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        await fetchLokasi(); // Refresh daftar lokasi
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await deleteLokasi(id);
        }
        return false;
      } else {
        print('Delete lokasi failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error deleting lokasi: $e');
      return false;
    }
  }

  Future<bool> fetchShifts() async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/shift',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      print('Fetch Shifts Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _shiftList = data.map((item) => Shift.fromJson(item)).toList();
        print('Parsed Shift List Length: ${_shiftList.length}');
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await fetchShifts(); // Coba ulang setelah refresh
        }
        return false;
      } else {
        print('Fetch shifts failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error fetching shifts: $e');
      return false;
    }
  }

  Future<bool> createShift(
    String shift,
    String jamMulai,
    String jamSelesai,
  ) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/shift',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
        body: jsonEncode({
          'shift': shift,
          'jam_mulai': jamMulai,
          'jam_selesai': jamSelesai,
        }),
      );

      print('Create Shift Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        await fetchShifts(); // Refresh daftar shift
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await createShift(shift, jamMulai, jamSelesai);
        }
        return false;
      } else {
        print('Create shift failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error creating shift: $e');
      return false;
    }
  }

  Future<bool> updateShift(
    int id,
    String shift,
    String jamMulai,
    String jamSelesai,
  ) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/shift/$id',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
        body: jsonEncode({
          'shift': shift,
          'jam_mulai': jamMulai,
          'jam_selesai': jamSelesai,
        }),
      );

      print('Update Shift Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await fetchShifts(); // Refresh daftar shift
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await updateShift(id, shift, jamMulai, jamSelesai);
        }
        return false;
      } else {
        print('Update shift failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating shift: $e');
      return false;
    }
  }

  Future<bool> deleteShift(int id) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/shift/$id',
    );
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      print('Delete Shift Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await fetchShifts(); // Refresh daftar shift
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await deleteShift(id);
        }
        return false;
      } else {
        print('Delete shift failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error deleting shift: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    if (!_isInitialized) await _initStorage();
    if (_user?.refreshToken == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/auth/refresh',
    );
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
          nama: _user!.nama,
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
      final nama = _storage.getString('nama');
      final email = _storage.getString('email');
      final role = _storage.getString('role');
      final token = _storage.getString('token');
      final refreshToken = _storage.getString('refresh_token');

      print(
        'LoadUser - ID: $id, Email: $email, Role: $role, Token: $token, Refresh: $refreshToken',
      );
      if (id != null &&
          nama != null &&
          email != null &&
          role != null &&
          token != null) {
        // refreshToken optional
        _user = User(
          id: id,
          nama: nama,
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
      'https://mbl.nipstudio.id/api_kehadiranmu/absensi',
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
          _absensiList = newItems;
        } else {
          _absensiList.addAll(newItems);
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
    String? tanggalAwal,
    String? tanggalAkhir,
    String? shift,
    int? userId,
    String? statusTelat,
  }) async {
    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/absensi',
    ).replace(
      queryParameters: {
        'page': page.toString(),
        'limit': '10',
        if (tanggalAwal != null) 'tanggal_awal': tanggalAwal,
        if (tanggalAkhir != null) 'tanggal_akhir': tanggalAkhir,
        if (shift != null) 'shift': shift,
        if (userId != null) 'user_id': userId.toString(),
        if (statusTelat != null) 'status_telat': statusTelat,
      },
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${user!.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> absensiData = data['data'];
        final newAbsensiList =
            absensiData.map((json) => Absensi.fromJson(json)).toList();

        if (page == 1) {
          _absensiList = newAbsensiList; // Update langsung
        } else {
          _absensiList.addAll(newAbsensiList); // Tambah data untuk pagination
        }
        _totalPages = data['total_pages']; // Update total pages
        notifyListeners(); // Beritahu UI bahwa data berubah
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await fetchAllAbsensi(
            page: page,
            tanggalAwal: tanggalAwal,
            tanggalAkhir: tanggalAkhir,
            shift: shift,
            userId: userId,
            statusTelat: statusTelat,
          );
        }
      }
      return false;
    } catch (e) {
      print('Error fetching absensi: $e');
      return false;
    }
  }

  Future<bool> fetchUsers({String? nama, String? role = 'user'}) async {
    if (_user?.token == null) return false;

    final queryParams = {
      if (nama != null) 'nama': nama,
      if (role != null) 'role': role,
    };
    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/users',
    ).replace(queryParameters: queryParams);
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );
      print('Fetch Users Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _userList = data.map((item) => UserAll.fromJson(item)).toList();
        print(
          'Parsed User List Length: ${_userList.length}',
        ); // Debug jumlah item
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await fetchUsers(nama: nama, role: role);
        }
        return false;
      } else {
        print('Fetch users failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error fetching users: $e');
      return false;
    }
  }

  // Create user
  Future<bool> createUser({
    required String nama,
    required String email,
    required String password,
    required String nomorTelepon,
    required String role,
  }) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/users',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'password': password,
          'nomor_telepon': nomorTelepon,
          'role': role,
        }),
      );
      print('Create User Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        await fetchUsers(); // Refresh list
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await createUser(
            nama: nama,
            email: email,
            password: password,
            nomorTelepon: nomorTelepon,
            role: role,
          );
        }
        return false;
      } else {
        print('Create user failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // Update user
  Future<bool> updateUser({
    required String id,
    required String nama,
    required String email,
    String? password,
    required String nomorTelepon,
    required String role,
  }) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/users/$id',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
        body: jsonEncode({
          'nama': nama,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          'nomor_telepon': nomorTelepon,
          'role': role,
        }),
      );
      print('Update User Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await fetchUsers(); // Refresh list
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await updateUser(
            id: id,
            nama: nama,
            email: email,
            password: password,
            nomorTelepon: nomorTelepon,
            role: role,
          );
        }
        return false;
      } else {
        print('Update user failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String id) async {
    if (_user?.token == null) return false;

    final url = Uri.parse(
      'https://mbl.nipstudio.id/api_kehadiranmu/admin/users/$id',
    );
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );
      print('Delete User Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await fetchUsers(); // Refresh list
        return true;
      } else if (response.statusCode == 401) {
        if (await refreshToken()) {
          return await deleteUser(id);
        }
        return false;
      } else {
        print('Delete user failed: ${jsonDecode(response.body)['message']}');
        return false;
      }
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
