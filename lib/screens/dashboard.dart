import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/auth_provider.dart';
import '../widgets/loading_dialog.dart';
import 'history.dart';
import 'login.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Fungsi untuk cek dan minta izin lokasi
  Future<bool> _checkAndRequestPermission(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Layanan lokasi dimatikan, silakan aktifkan GPS'),
          ),
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Izin lokasi ditolak')));
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Izin lokasi ditolak permanen, buka pengaturan untuk mengizinkan',
            ),
          ),
        );
        return false;
      }
      return true;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inisialisasi lokasi: $e')));
      return false;
    }
  }

  // Fungsi untuk ambil lokasi
  Future<Position?> _getCurrentLocation(BuildContext context) async {
    bool permissionGranted = await _checkAndRequestPermission(context);
    if (!permissionGranted) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      return null;
    }
  }

  // Fungsi untuk ambil foto
  Future<File?> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800, // Kompres ukuran
        maxHeight: 800,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      return null;
    }
  }

  Future<String?> _uploadPhoto(
    BuildContext context,
    File image,
    String token,
  ) async {
    final url = Uri.parse(
      'http://10.0.2.2/api_kehadiranmu/absensi/upload-foto',
    );
    try {
      var request =
          http.MultipartRequest('POST', url)
            ..headers['Authorization'] = 'Bearer $token'
            ..files.add(await http.MultipartFile.fromPath('foto', image.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      print('Upload Photo Response: ${response.statusCode} - $responseBody');
      if (response.statusCode == 200) {
        return data['foto_path'];
      } else if (response.statusCode == 401) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (await authProvider.refreshToken()) {
          return await _uploadPhoto(context, image, authProvider.user!.token);
        } else {
          _handleTokenExpired(context);
          return null;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: ${data['message']}')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error upload foto: $e')));
      return null;
    }
  }

  void _handleTokenExpired(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sesi Anda telah habis, silakan login kembali')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Berhasil logout')));
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _absenMasuk(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    print('Absen Masuk - Token: $token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token tidak ditemukan, silakan login ulang')),
      );
      return;
    }

    showLoadingDialog(context, 'Memproses absen...'); // Gunakan fungsi umum
    final position = await _getCurrentLocation(context);
    if (position == null) {
      Navigator.pop(context);
      return;
    }

    final image = await _pickImage(context);
    if (image == null) {
      Navigator.pop(context);
      return;
    }

    final fotoPath = await _uploadPhoto(context, image, token);
    if (fotoPath == null) {
      Navigator.pop(context);
      return;
    }

    final url = Uri.parse('http://10.0.2.2/api_kehadiranmu/absensi');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'foto_path': fotoPath,
        }),
      );

      print('Response: ${response.statusCode} - ${response.body}');
      Navigator.pop(context);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Absen masuk berhasil: ${jsonDecode(response.body)['message']}',
            ),
          ),
        );
      } else if (response.statusCode == 401) {
        if (await authProvider.refreshToken()) {
          await _absenMasuk(context);
        } else {
          _handleTokenExpired(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${jsonDecode(response.body)['message']}'),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _absenKeluar(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    print('Absen Keluar - Token: $token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token tidak ditemukan, silakan login ulang')),
      );
      return;
    }

    showLoadingDialog(context, 'Memproses absen...'); // Gunakan fungsi umum
    final position = await _getCurrentLocation(context);
    if (position == null) {
      Navigator.pop(context);
      return;
    }

    final url = Uri.parse('http://10.0.2.2/api_kehadiranmu/absensi/keluar');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      print('Response: ${response.statusCode} - ${response.body}');
      Navigator.pop(context);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Absen keluar berhasil: ${jsonDecode(response.body)['message']}',
            ),
          ),
        );
      } else if (response.statusCode == 401) {
        if (await authProvider.refreshToken()) {
          await _absenKeluar(context);
        } else {
          _handleTokenExpired(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${jsonDecode(response.body)['message']}'),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - Kehadiranmu'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child:
            user.role == 'admin'
                ? _buildAdminDashboard()
                : _buildUserDashboard(context),
      ),
    );
  }

  Widget _buildUserDashboard(BuildContext context) {
    return Column(
      children: [
        Text('Selamat datang, Karyawan!', style: TextStyle(fontSize: 20)),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _absenMasuk(context),
          child: Text('Absen Masuk'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _absenKeluar(context),
          child: Text('Absen Keluar'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HistoryScreen()),
            );
          },
          child: Text('Lihat Riwayat Absensi'),
        ),
      ],
    );
  }

  Widget _buildAdminDashboard() {
    return Column(
      children: [
        Text('Selamat datang, Admin!', style: TextStyle(fontSize: 20)),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {}, // Nanti isi dengan rekap absensi
          child: Text('Lihat Rekap Absensi'),
        ),
      ],
    );
  }
}
