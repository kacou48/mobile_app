import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/components/text_component.dart';
import 'package:tadiago/more/models/others_models.dart';
import 'package:tadiago/more/providers/other_provider.dart';
import 'package:tadiago/utils/color.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _sendingContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final othersProvider = Provider.of<OtherProvider>(context, listen: false);

      // Create an instance of the Abus model
      final contact = Contact(
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        contenu: _descriptionController.text.trim(),
      );

      final success = await othersProvider.contactUs(contact);

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
        title: "Contactez-nous",
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
                        "Notre équipe est à votre disposition pour répondre à toutes vos questions.",
                    fw: FontWeight.w300,
                    color: Colors.black54,
                    txtSize: 20,
                    family: "Bold",
                  ),
                ),
                SizedBox(height: 30),
                RoudedInputFied(
                  hintText: "votre nom",
                  icon: Icons.title,
                  controller: _nomController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Veuillez entrer vore nom'
                      : null,
                ),
                SizedBox(height: 10),
                RoudedInputFied(
                  hintText: "votre email",
                  icon: Icons.email,
                  controller: _emailController,
                  textInputType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Veuillez entrer votre email'
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
                    onPressed: _sendingContact,
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
