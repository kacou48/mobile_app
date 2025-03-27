import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/accounts/screen/login_screen.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/config/themes.dart';
import 'package:tadiago/home/main_home_screen.dart';
import 'package:tadiago/utils/color.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _nameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _telephoneController = TextEditingController();

  String? _civility = 'M.'; // Valeur par défaut
  String? _status = 'Acheteur'; // Valeur par défaut

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _nameController.dispose();
    _firstnameController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        firstname: _firstnameController.text.trim(),
        telephone: _telephoneController.text.trim(),
        civility: _civility!,
        status: _status!,
      );

      if (!mounted) return;

      if (success) {
        String registeredEmail = _emailController.text;
        Navigator.pushNamed(context, '/verify_code_page',
            arguments: registeredEmail);
      } else {
        // Afficher l'erreur
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                const Upside(imgUrl: "assets/images/login1.png"),
                Padding(
                  //padding: const EdgeInsets.only(top: 320.0),
                  padding: const EdgeInsets.only(top: 280.0),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),
                        )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Center(
                                child: Text(
                                  "Inscription gratuite !",
                                  style: AppTextStyles.headlineSmall,
                                ),
                              ),
                              RoudedInputFied(
                                hintText: "Nom",
                                icon: Icons.person,
                                controller: _nameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom';
                                  }
                                  return null;
                                },
                              ),
                              RoudedInputFied(
                                hintText: "Prenom",
                                icon: Icons.person,
                                controller: _firstnameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre prenom';
                                  }
                                  return null;
                                },
                              ),
                              RoudedInputFied(
                                hintText: "Email",
                                icon: Icons.email,
                                controller: _emailController,
                                textInputType: TextInputType.emailAddress,
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
                              RoudedInputFied(
                                hintText: "Telephone",
                                icon: Icons.phone,
                                controller: _telephoneController,
                                textInputType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre numero tel';
                                  }
                                  return null;
                                },
                              ),
                              RoundedDropdownField(
                                hintText: "Civilité",
                                icon: Icons.person,
                                items: ["Monsieur", "Madame"],
                                onChanged: (value) {
                                  setState(() {
                                    _civility =
                                        (value == "Monsieur") ? "M." : "Mme";
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez sélectionner une civilité';
                                  }
                                  return null;
                                },
                              ),
                              RoundedDropdownField(
                                hintText: "Statut",
                                icon: Icons.account_box,
                                items: ["Acheteur", "Vendeur"],
                                onChanged: (value) {
                                  setState(() {
                                    _status = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez sélectionner un statut';
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
                              RoudedPasswordFied(
                                placeholder: "Confirmez Password",
                                controller: _password2Controller,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez confirmer votre mot de passe';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Les mots de passe ne correspondent pas';
                                  }
                                  return null;
                                },
                              ),
                              if (authProvider.isLoading)
                                const CircularProgressIndicator()
                              else
                                RoudedButton(
                                  text: "S'inscrire",
                                  press: _handleRegister,
                                ),
                              const SizedBox(
                                height: 10,
                              ),
                              RoudedButton(
                                text: "S'inscrire via Google",
                                isGoogleButton: true,
                                press: _handleGoogleLogin,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              UnderPart(
                                title: "Avez vous deja un compte?",
                                navigatorText: "Se connecter Ici",
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen()));
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
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
}
