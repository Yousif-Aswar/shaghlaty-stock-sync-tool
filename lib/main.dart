import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const StockSyncApp());
}

class StockSyncApp extends StatelessWidget {
  const StockSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Sync',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const LoginScreen(),
    );
  }
}
