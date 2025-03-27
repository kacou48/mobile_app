import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/components/text_component.dart';
import 'package:tadiago/utils/color.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  Future<void> _sendNewPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.sendNewPassWord(
        _password2Controller.text.trim(), //new password
        _passwordController.text.trim(), //old passwor
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reponse: ${result["message"]}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result["message"]}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
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
                    txt: "Saisissez votre ancien et nouveau mot de passe",
                    fw: FontWeight.w300,
                    color: Colors.black54,
                    txtSize: 20,
                    family: "Bold",
                  ),
                ),
                SizedBox(height: 30),
                RoudedPasswordFied(
                  placeholder: "Ancien mot de passe",
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre ancien mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                RoudedPasswordFied(
                  placeholder: "Nouveau mot de passe",
                  controller: _password2Controller,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nouveau mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: _sendNewPassword,
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
