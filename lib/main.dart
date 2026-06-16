import 'package:flutter/material.dart';
import 'package:skyride/database/database_helper.dart';
import 'package:skyride/theme/app_theme.dart';
import './Splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}
