import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/accounts/screen/login_screen.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/components/text_component.dart';
import 'package:tadiago/utils/color.dart'; //ResetPassword

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _password2Controller.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendingVerifyCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.sendResetPassWordVerify(
          _codeController.text.trim(), _passwordController.text.trim());

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result["success"]) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result["message"]}'),
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
    return Scaffold(
      appBar: CustomAppBar(
        title: "Changer son mot de passe",
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 50),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: TextComponents(
                    txt:
                        "Veuillez copier et coller le code reçu, puis saisir un nouveau mot de passe. Attention : ce code expire au bout de 10 minutes.",
                    fw: FontWeight.w300,
                    color: Colors.black54,
                    txtSize: 20,
                    family: "Bold",
                  ),
                ),
                SizedBox(height: 30),
                RoudedInputFied(
                  hintText: "Entrez le code reçu par mail",
                  icon: Icons.code,
                  controller: _codeController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le code reçu par mail';
                    }
                    return null;
                  },
                ),
                RoudedPasswordFied(
                  placeholder: "Password",
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nouveau mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                RoudedPasswordFied(
                  placeholder: "Confirmez le mot de passe",
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
                Center(
                  child: ElevatedButton(
                    onPressed: _sendingVerifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Soumettre",
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
