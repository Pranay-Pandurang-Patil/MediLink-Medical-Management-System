import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:medilink/features/auth/screens/login_screen.dart';
import 'package:medilink/features/dashboard/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Give Firebase time to restore the authentication session.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _isNavigating) return;

    final User? user = FirebaseAuth.instance.currentUser;

    debugPrint(
      'MediLink Firebase user: ${user?.email ?? 'NO USER'}',
    );

    _isNavigating = true;

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
            (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_full.png',
                width: 220,
              ),

              const SizedBox(height: 24),

              const Text(
                'MediLink',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Smart Medical Shop Management',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: 80,
                height: 80,
                child: Lottie.asset(
                  'assets/animations/Pulse.json',
                  repeat: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}