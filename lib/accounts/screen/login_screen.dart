import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/accounts/screen/email_for_reset_password.dart';
import 'package:tadiago/accounts/screen/signup_screen.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/config/themes.dart';
import 'package:tadiago/home/main_home_screen.dart';
import 'package:tadiago/utils/color.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();
    if (!mounted) return;
    if (success) {
      // Redirection vers la page d'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainHomeScreen()),
      );
    } else {
      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Échec de la connexion Google'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: redColor,
          showCloseIcon: true,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Redirection vers la page d'accueil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainHomeScreen()),
        );
      } else {
        // Afficher l'erreur
        debugPrint("erreur: ${authProvider.error}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Une erreur est survenue'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: redColor,
            showCloseIcon: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                const Upside(imgUrl: "assets/images/login1.png"),
                Padding(
                  padding: const EdgeInsets.only(top: 280.0),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 7),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Center(
                                child: Text(
                                  "Connectez-vous",
                                  style: AppTextStyles.headlineSmall,
                                ),
                              ),
                              RoudedInputFied(
                                hintText: "Email",
                                icon: Icons.email,
                                controller: _emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Veuillez entrer un email valide';
                                  }
                                  return null;
                                },
                              ),
                              RoudedPasswordFied(
                                placeholder: "Password",
                                controller: _passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  if (value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  return null;
                                },
                              ),
                              _buildRememberMe(),
                              if (authProvider.isLoading)
                                const CircularProgressIndicator()
                              else
                                RoudedButton(
                                  text: 'Se Connecter',
                                  press: _handleLogin,
                                ),
                              const SizedBox(height: 10),
                              if (authProvider.isGoogleLoading)
                                const CircularProgressIndicator()
                              else
                                RoudedButton(
                                  text: "Connexion via Google",
                                  isGoogleButton: true,
                                  press: _handleGoogleLogin,
                                ),
                              const SizedBox(height: 10),
                              UnderPart(
                                title: "Vous n'avez pas de compte?",
                                navigatorText: "S'inscrire Ici",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignupScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EmailForResetPassword(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Mot de passe oublié?',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontFamily: 'Regulare',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return Padding(
      padding: const EdgeInsets.only(left: 50, right: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Se souvenir de moi',
            style: AppTextStyles.labelMedium,
          ),
          Transform.scale(
            scale: 0.8, // ✅ Réduit la taille du switch
            child: Switch(
              value: _rememberMe,
              activeColor: kPrimaryColor,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
