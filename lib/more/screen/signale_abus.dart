import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/components/text_component.dart';
import 'package:tadiago/more/models/others_models.dart';
import 'package:tadiago/more/providers/other_provider.dart';
import 'package:tadiago/utils/color.dart';

class SignaleAbus extends StatefulWidget {
  const SignaleAbus({super.key});

  @override
  State<SignaleAbus> createState() => _SignaleAbusState();
}

class _SignaleAbusState extends State<SignaleAbus> {
  final _formKey = GlobalKey<FormState>();
  String? _signalementSelected;
  int? _userId;
  int? _annonceId;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch the ad ID from route arguments
    _annonceId = ModalRoute.of(context)!.settings.arguments as int?;
    debugPrint("id: $_annonceId");
    if (_annonceId == null) {
      throw Exception('Annonce ID is required');
    }

    // Fetch the user ID from the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    _userId = user?.id;
  }

  Future<void> _sendingAbus() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final othersProvider = Provider.of<OtherProvider>(context, listen: false);

      // Create an instance of the Abus model
      final abus = Abus(
        annonceType: _signalementSelected!,
        message: _descriptionController.text.trim(),
        userId: _userId!,
        annonceId: _annonceId!,
      );

      final success = await othersProvider.reportAbus(abus);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message reçu avec succès'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur est survenue, réessayez ultérieurement'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      // Show a message if the form is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Signaler un abus",
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
                    txt: "Alertez-nous d'une annonce suspecte ou inappropriée.",
                    fw: FontWeight.w300,
                    color: Colors.black54,
                    txtSize: 20,
                    family: "Bold",
                  ),
                ),
                SizedBox(height: 30),
                RoundedDropdownField(
                  hintText: "Sélectionner un type...",
                  icon: Icons.signal_cellular_0_bar,
                  items: ["spam", "offensive", "fraude", "autre"],
                  onChanged: (value) {
                    setState(() {
                      _signalementSelected = value!;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Veuillez sélectionner un type de signalement'
                      : null,
                ),
                SizedBox(height: 10),
                TextFieldContainer(
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: null,
                    minLines: 4,
                    maxLength: 2000,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: 'Décrivez en détail le problème rencontré...',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Veuillez entrer votre message'
                        : null,
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: _sendingAbus,
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
