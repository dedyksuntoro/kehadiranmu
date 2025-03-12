import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
import 'screens/dashboard.dart';
import 'services/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: KehadiranmuApp(),
    ),
  );
}

class KehadiranmuApp extends StatelessWidget {
  const KehadiranmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kehadiranmu',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          print('Consumer build, User: ${authProvider.user}');
          if (authProvider.user != null) {
            return DashboardScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
