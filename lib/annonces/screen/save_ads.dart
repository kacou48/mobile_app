import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/annonces/models/ads_models.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
//import 'package:tadiago/annonces/utils/categories_ads.dart';
import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/utils/color.dart';

class SaveAds extends StatefulWidget {
  const SaveAds({super.key});

  @override
  State<SaveAds> createState() => _SaveAdsState();
}

class _SaveAdsState extends State<SaveAds> {
  // ignore: unused_field
  List<Map<String, dynamic>> _subCategoriesList = [];
  List<Map<String, dynamic>> _categoriesList = [];

  //List<Category> _categories = [];
  //List<SubCategory> _subCategories = [];

  int? _cateSelected;
  int? _subCateSelected;
  String _locationSelected = "Bamako";
  String _transactionType = "Vente";
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCategories();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendingAds() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final adsProvider = Provider.of<AdsProvider>(context, listen: false);
      final double priceValue = double.parse(_priceController.text.trim());
      final success = await adsProvider.saveAds(
        category: _cateSelected!,
        subCategory: _subCateSelected!,
        price: priceValue,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        localisation: _locationSelected,
        transactionType: _transactionType,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushNamed(context, '/ads_attachement');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adsProvider.error ?? 'Une erreur est survenue'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _getSubCate() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);

    if (_cateSelected != null) {
      List<SubCategory> subCategories =
          await adsProvider.fetchAdSubcategories(_cateSelected!);

      // Stocker ID et Nom
      _subCategoriesList = subCategories
          .map((subCat) => {"id": subCat.id, "name": subCat.name})
          .toList();

      setState(() {});
    }
  }

  Future<void> _getCategories() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    List<Category> categories = await adsProvider.fetchCategories();

    _categoriesList =
        categories.map((cat) => {"id": cat.id, "name": cat.name}).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      //backgroundColor: const Color(0xFFF5F6F9),
      appBar: CustomAppBar(
        title: "Publier une annonce",
        onBackPressed: () {
          Navigator.pushNamed(context, '/main_home_page');
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RoundedDropdownField(
                hintText: "Catégorie",
                icon: Icons.category,
                //items: _categoriesList,
                items: _categoriesList
                    .map((cat) => cat["name"] as String)
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _cateSelected = int.tryParse(_categoriesList
                        .firstWhere(
                            (category) => category["name"] == value)["id"]
                        .toString());
                    _subCateSelected = null;
                    _getSubCate();
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez sélectionner une catégorie'
                    : null,
              ),

              RoundedDropdownField(
                hintText: "Sous Catégorie",
                icon: Icons.category,
                items: _subCategoriesList
                    .map((subCat) => subCat["name"] as String)
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _subCateSelected = int.tryParse(_subCategoriesList
                        .firstWhere((subCat) => subCat["name"] == value)["id"]
                        .toString());
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez sélectionner une sous-catégorie'
                    : null,
              ),

              // Titre
              RoudedInputFied(
                hintText: "Titre",
                icon: Icons.title,
                controller: _titleController,
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un titre'
                    : null,
              ),

              // Description
              TextFieldContainer(
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: null,
                  minLines: 4,
                  maxLength: 2000,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Veuillez entrer une description'
                      : null,
                ),
              ),

              // Prix
              RoudedInputFied(
                hintText: "Prix",
                icon: Icons.price_change,
                controller: _priceController,
                textInputType: TextInputType.numberWithOptions(decimal: false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  final int? intValue = int.tryParse(value.trim());
                  if (intValue == null || intValue <= 0) {
                    return 'Veuillez entrer un nombre entier positif';
                  }
                  return null; // Aucune erreur
                },
              ),

              // Type de transaction
              RoundedDropdownField(
                hintText: "Type de transaction",
                icon: Icons.transform,
                items: ["vente", "location", "echange"],
                onChanged: (value) {
                  setState(() {
                    _transactionType = value!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez sélectionner un type de transaction'
                    : null,
              ),

              // Localisation
              RoundedDropdownField(
                hintText: "Localisation",
                icon: Icons.location_on,
                items: ["Bamako", "Sikasso", "Kayes", "Mopti"], // À compléter
                onChanged: (value) {
                  setState(() {
                    _locationSelected = value!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez sélectionner une localité'
                    : null,
              ),

              // Bouton de soumission
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _sendingAds,
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
                          "Publier l’annonce",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
