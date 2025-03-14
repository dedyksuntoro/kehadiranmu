import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/auth_provider.dart';
import '../models/user.dart';
import '../widgets/loading_dialog.dart';
import 'dashboard.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('http://10.0.2.2/api_kehadiranmu/auth/login');

    showLoadingDialog(context, 'Sedang login...');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      print('Login Response: ${response.statusCode} - ${response.body}');
      Navigator.pop(context); // Tutup loading
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        // Dekode access_token untuk mendapatkan data user
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        final userData = decodedToken['data'];

        final user = User(
          id: userData['id'].toString(), // Pastikan jadi String
          email: userData['email'],
          role: userData['role'],
          token: accessToken,
          refreshToken: refreshToken,
        );

        print(
          'Login - ID: ${user.id}, Email: ${user.email}, Role: ${user.role}, Token: ${user.token}, Refresh Token: ${user.refreshToken}',
        );
        await authProvider.setUser(user);
        print(
          'Login - User after save: ${authProvider.user?.email}, Role: ${authProvider.user?.role}, Token: ${authProvider.user?.token}',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage =
              jsonDecode(response.body)['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      Navigator.pop(context);
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login - Kehadiranmu')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Login')),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text('Belum punya akun? Daftar di sini'),
            ),
          ],
        ),
      ),
    );
  }
}
