import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/auth_provider.dart';
import '../widgets/loading_dialog.dart';
import 'admin/lokasi.dart';
import 'admin/rekap_absen.dart';
import 'admin/shift.dart';
import 'admin/employee.dart';
import 'history.dart';
import 'login.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0; // Indeks tab yang dipilih
  late AnimationController _masukController; // Untuk tombol Absen Masuk
  late AnimationController _keluarController; // Untuk tombol Absen Keluar

  @override
  void initState() {
    super.initState();
    _masukController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _keluarController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _masukController.dispose();
    _keluarController.dispose();
    super.dispose();
  }

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

  Future<Position?> _getCurrentLocation(BuildContext context) async {
    bool permissionGranted = await _checkAndRequestPermission(context);
    if (!permissionGranted) return null;

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

  Future<File?> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) return File(pickedFile.path);
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

    showLoadingDialog(context, 'Memproses data...');
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
        final errorMessage = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
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

    showLoadingDialog(context, 'Memproses data...');
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
      body:
          user.role == 'admin'
              ? _buildAdminDashboard(context, _selectedIndex)
              : _buildUserDashboard(context, _selectedIndex),
      bottomNavigationBar:
          user.role == 'admin'
              ? _buildAdminBottomNavBar()
              : _buildUserBottomNavBar(),
    );
  }

  Widget _buildAdminDashboard(BuildContext context, int index) {
    final List<Widget> adminPages = [
      RekapAbsenScreen(),
      ShiftScreen(),
      LokasiScreen(),
      EmployeeManagementScreen(),
      Center(child: Text('Logout akan ditangani di BottomNavBar')),
    ];
    return adminPages[index];
  }

  BottomNavigationBar _buildAdminBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == 4) {
          _showLogoutDialog(context);
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Absensi'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Shift'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Lokasi'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Karyawan'),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout, color: Colors.red),
          label: 'Logout',
        ),
      ],
    );
  }

  Widget _buildUserDashboard(BuildContext context, int index) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user!;
    final double screenWidth =
        MediaQuery.of(context).size.width; // Ambil lebar layar
    final double dynamicPadding = screenWidth; // 5% dari lebar layar
    final double maxPadding = 32.0; // Batas maksimum padding
    final double minPadding = 16.0; // Batas minimum padding
    final double responsivePadding = dynamicPadding.clamp(
      minPadding,
      maxPadding,
    ); // Batasi rentang

    final List<Widget> userPages = [
      // Tab 0: Absen
      Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [Colors.grey.shade300, Colors.white],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
        child: Padding(
          padding: EdgeInsets.all(responsivePadding), // Gunakan padding dinamis
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.nama,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center, // Teks tetap center di dalam batas
                overflow:
                    TextOverflow
                        .ellipsis, // Tambah ellipsis jika terlalu panjang
              ),
              SizedBox(
                height: responsivePadding * 0.025,
              ), // Sesuaikan jarak dengan padding (10/16)
              StreamBuilder(
                stream: Stream.periodic(Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Text(
                    'Waktu saat ini: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                    style: TextStyle(fontSize: 16),
                  );
                },
              ),
              SizedBox(height: responsivePadding * 1.5), // 40/16 = 2.5x padding
              GestureDetector(
                onTapDown: (_) => _masukController.forward(),
                onTapUp:
                    (_) => _masukController.reverse().then(
                      (_) => _absenMasuk(context),
                    ),
                onTapCancel: () => _masukController.reverse(),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 1.0,
                    end: 0.95,
                  ).animate(_masukController),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsivePadding * 1.25,
                        horizontal: responsivePadding * 2.5,
                      ), // 20/16 = 1.25, 40/16 = 2.5
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login, color: Colors.blue),
                          SizedBox(width: responsivePadding * 0.625), // 10/16
                          Text(
                            'Absen Masuk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsivePadding * 1.25), // 20/16
              GestureDetector(
                onTapDown: (_) => _keluarController.forward(),
                onTapUp:
                    (_) => _keluarController.reverse().then(
                      (_) => _absenKeluar(context),
                    ),
                onTapCancel: () => _keluarController.reverse(),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 1.0,
                    end: 0.95,
                  ).animate(_keluarController),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsivePadding * 1.25,
                        horizontal: responsivePadding * 2.5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: responsivePadding * 0.625),
                          Text(
                            'Absen Keluar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsivePadding * 2.5), // 40/16
              Text(
                'Silakan absen untuk memulai atau mengakhiri hari ini!',
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      // Tab 1: Riwayat Absensi
      HistoryScreen(),
      // Tab 2: Logout (Placeholder)
      Center(child: Text('Logout akan ditangani di BottomNavBar')),
    ];

    return userPages[index];
  }

  BottomNavigationBar _buildUserBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == 2) {
          _showLogoutDialog(context);
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'Absen'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout, color: Colors.red),
          label: 'Logout',
        ),
      ],
    );
  }
}
