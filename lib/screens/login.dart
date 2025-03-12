import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_provider.dart';
import '../models/user.dart';
import '../widgets/loading_dialog.dart'; // Import loading_dialog.dart
import 'dashboard.dart';

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

    showLoadingDialog(context, 'Sedang login...'); // Gunakan fungsi umum
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
        final user = User(
          id: data['id'] ?? 0,
          email: _emailController.text,
          role: data['role'] ?? 'karyawan',
          token: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        print(
          'Login - Token: ${user.token}, Refresh Token: ${user.refreshToken}',
        );
        await authProvider.setUser(user);
        print(
          'Login - User after save: ${authProvider.user?.email}, Token: ${authProvider.user?.token}, Refresh: ${authProvider.user?.refreshToken}',
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
      Navigator.pop(context); // Tutup loading kalau error
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
          ],
        ),
      ),
    );
  }
}
