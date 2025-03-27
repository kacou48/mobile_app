import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/models/user_models.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
//import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/utils/color.dart';
//import 'package:tadiago/utils/constant.dart';
//myBaseUrl

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late User _user;
  bool _isLoading = false;
  bool _isdeletedLoading = false;
  //List<String> _vendorChoices = [];

  File? _image;
  //String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _user = authProvider.user!;
      // if (_user.status == 'Vendeur') {
      //   _loadVendorChoices();
      // }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _loadVendorChoices() async {
  //   try {
  //     final choices = await authProvider.getVendorChoices();
  //     setState(() => _vendorChoices = List<String>.from(choices));
  //   } catch (e) {
  //     print('Error loading vendor choices: $e');
  //   }
  // }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final updatedUser = _user.copyWith(
          id: _user.id,
          email: _user.email,
          name: _user.name,
          firstname: _user.firstname,
          telephone: _user.telephone,
          civility: _user.civility,
          status: _user.status,
          city: _user.city,
          imageUrl: _user.imageUrl,
          isActive: _user.isActive,
          vendor: _user.status == 'Vendeur'
              ? Vendor(
                  description: _user.vendor?.description,
                  lieu: _user.vendor?.lieu)
              : null,
        );

        await authProvider.updateUser(updatedUser.toJson()); // fetch data

        // Use a GlobalKey for the Scaffold to avoid context issues
        if (mounted) {
          // Check if the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil mis à jour avec success!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;

      setState(() {
        _image = File(pickedFile.path);
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        String? imageUrl = await authProvider.updateProfileImage(_image!);

        if (!mounted) return;

        if (imageUrl != null) {
          setState(() {
            //_imageUrl = imageUrl;
            _user = _user.copyWith(imageUrl: imageUrl);
          });

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.updateUser(_user.toJson()); // Met à jour le User

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Image mise à jour !")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Erreur de mise à jour")));
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    }
  }

  Future<void> _deleteAccount(context, int userId) async {
    setState(() {
      _isdeletedLoading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.deleteMyAccount(context, userId);
    } catch (e) {
      setState(() {
        _isdeletedLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${authProvider.error}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: redColor,
        ),
      );
    } finally {
      setState(() {
        _isdeletedLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      // appBar: CustomAppBar(
      //   title: "Mes Infos Personnelles",
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(width: 4, color: Colors.white),
                                  boxShadow: [
                                    BoxShadow(
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                        color: Colors.black45)
                                  ],
                                  shape: BoxShape.circle,
                                  image: DecorationImage(image: NetworkImage(
                                      //'$myBaseUrl${_user.imageUrl}'
                                      '${_user.imageUrl}'), fit: BoxFit.cover)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          width: 4, color: Colors.white),
                                      color: Colors.blue),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextFormField(
                        initialValue: _user.name,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _user = _user.copyWith(name: value);
                          });
                        },
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        initialValue: _user.firstname,
                        decoration: const InputDecoration(labelText: 'Prenom'),
                        onChanged: (value) {
                          setState(() {
                            _user = _user.copyWith(firstname: value);
                          });
                        },
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        initialValue: _user.email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: false, // Make email non-editable
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        initialValue: _user.telephone,
                        decoration:
                            const InputDecoration(labelText: 'Telephone'),
                        onChanged: (value) {
                          setState(() {
                            _user = _user.copyWith(telephone: value);
                          });
                        },
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Statut'),
                        value: _user.status,
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'Vendeur',
                            child: Text('Vendeur'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Acheteur',
                            child: Text('Acheteur'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _user = _user.copyWith(status: value);
                          });
                        },
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      if (_user.status == 'Vendeur') ...[
                        TextFormField(
                          initialValue: _user.vendor?.description,
                          maxLines: null,
                          minLines: 3,
                          keyboardType: TextInputType.multiline,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          onChanged: (value) {
                            setState(() {
                              _user = _user.copyWith(
                                vendor:
                                    _user.vendor?.copyWith(description: value),
                              );
                            });
                          },
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          initialValue: _user.vendor?.lieu,
                          decoration: const InputDecoration(labelText: 'Lieu'),
                          onChanged: (value) {
                            setState(() {
                              _user = _user.copyWith(
                                vendor: _user.vendor?.copyWith(lieu: value),
                              );
                            });
                          },
                        ),
                      ],
                      SizedBox(
                        height: 15,
                      ),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: redColor,
                            padding: EdgeInsets.symmetric(horizontal: 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text(
                          'Mettre à jour',
                          style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 2,
                              color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 18,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/change_password');
                            }, //_changePassword,
                            child: const Text('Modifier mot de passe'),
                          ),
                          TextButton(
                            onPressed: _isdeletedLoading
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text(
                                              'Confirmer la suppression'),
                                          content: const Text(
                                              'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Fermer la boîte de dialogue
                                              },
                                              child: const Text('Annuler',
                                                  style: TextStyle(
                                                      color: Colors.grey)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _deleteAccount(context, 100);
                                              },
                                              child: _isdeletedLoading
                                                  ? const CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.red),
                                                    )
                                                  : const Text('Supprimer',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                            child: _isdeletedLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.red),
                                  )
                                : const Text(
                                    'Supprimer le compte',
                                    style: TextStyle(color: Colors.red),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
