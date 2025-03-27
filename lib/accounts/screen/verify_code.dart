import 'dart:async';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class VerifyCode extends StatefulWidget {
  const VerifyCode({super.key});

  @override
  State<VerifyCode> createState() => _VerifyCodeState();
}

class _VerifyCodeState extends State<VerifyCode> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? validPin;
  String? userEmail;
  bool isLoading = true;
  String? errorMessage;
  Timer? _timer;
  bool _isLoadingResend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //final arguments = ModalRoute.of(context)?.settings.arguments;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      userEmail = authProvider.getTemporaryEmail();
      if (userEmail != null) {
        setState(() {
          userEmail = userEmail;
          isLoading = true;
          errorMessage = null;
        });

        _startTimeout();
        await _fetchVerificationCode();
      }
    });
  }

  Future<void> _fetchVerificationCode() async {
    if (userEmail == null) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.getVerificationCode(userEmail!);
      if (mounted) {
        setState(() {
          isLoading = false;
          if (result['success']) {
            validPin = result['verification_code'];
          } else {
            errorMessage = result['message'];
          }
          _timer?.cancel();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Échec de récupération du code.';
          _timer?.cancel();
        });
      }
    }
  }

  void _startTimeout() {
    _timer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Délai dépassé. Veuillez réessayer.';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _verifyContain(),
    );
  }

  Widget _verifyContain() {
    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                _headingText(),
                const SizedBox(height: 20),
                _subHeadingText(),
                _emailText(),
              ],
            ),
            isLoading
                ? const CircularProgressIndicator()
                : errorMessage != null
                    ? Text(errorMessage!,
                        style: const TextStyle(color: Colors.red))
                    : _pinInputForm(),
            _resendCodeLink(),
          ],
        ),
      ),
    );
  }

  Widget _headingText() {
    return const Text(
      "Code de Vérification",
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 30),
    );
  }

  Widget _subHeadingText() {
    return const Text(
      "Entrez le code envoyé à cet e-mail :",
      style: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black38),
    );
  }

  Widget _emailText() {
    return Text(
      userEmail ?? "Email inconnu",
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
    );
  }

  Widget _resendCodeLink() {
    return InkWell(
      onTap: _isLoadingResend ? null : _resendCode,
      child: _isLoadingResend
          ? const CircularProgressIndicator()
          : Text(
              "Vous n'avez pas reçu de code ?\nRedemander le Code",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.primary),
            ),
    );
  }

  Future<void> _resendCode() async {
    if (userEmail == null) return;

    setState(() {
      _isLoadingResend = true;
      errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.getVerificationCode(userEmail!);

      if (mounted) {
        setState(() {
          _isLoadingResend = false;
          if (result['success']) {
            validPin = result['verification_code'];
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Code de vérification renvoyé !')));
          } else {
            errorMessage = result['message'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingResend = false;
          errorMessage = 'Échec de l’envoi du code.';
        });
      }
    }
  }

  Widget _pinInputForm() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Pinput(
            validator: (value) => value == validPin ? null : "Code incorrect",
            onCompleted: _validatePin,
            errorBuilder: (errorText, pin) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Text(
                    errorText ?? "",
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                  ),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => formKey.currentState!.validate(),
            child: const Text(
              "Valider",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validatePin(String pin) async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final result = await authProvider.toActivateUser(userEmail!, pin);

        if (mounted) {
          setState(() {
            isLoading = false;
            if (result['success']) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login_page', (route) => false);
              authProvider.clearTemporaryEmail();
            } else {
              errorMessage = result['message'];
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'Une erreur est survenue lors de la vérification.';
          });
        }
      }
    }
  }
}
