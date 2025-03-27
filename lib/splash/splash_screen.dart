import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/accounts/screen/login_screen.dart';
//import 'package:tadiago/annonces/providers/ads_provider.dart';
//import 'package:tadiago/accounts/screen/signup_screen.dart';
//import 'package:tadiago/components/text_component.dart';
import 'package:tadiago/home/main_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Initialize auth state
      if (!authProvider.isInitialized) {
        await authProvider.initializeAuth();
      }

      // Minimum splash screen duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });

      // Navigate based on auth state
      _handleNavigation();
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _handleNavigation() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      _navigateToHome();
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainHomeScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Stack(
            children: [
              // Logo and app name
              Center(
                child: SizedBox(
                  height: 240,
                  width: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/logo.png",
                        scale: 1.2,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Application de petites annonces",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Loading indicator or error message
              if (_isInitializing || authProvider.isLoading)
                const Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Error message if any
              if (authProvider.error != null && !_isInitializing)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authProvider.error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
