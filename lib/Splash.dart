import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:skyride/theme/app_theme.dart';
import './bording.dart';
import './navigation/navigation.dart';

class Splash extends StatefulWidget {
  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Delay to show splash screen
    await Future.delayed(const Duration(seconds: 5));

    if (token != null && token.isNotEmpty) {
      final userId = prefs.getString('userId') ?? 'guest';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Navigationbar(sessionKey: userId)),
      );
    } else {
      // If token is not saved, go to onboarding screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Image.asset(
          'assets/images/logo2.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
