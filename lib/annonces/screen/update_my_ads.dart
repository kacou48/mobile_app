import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/screen/widgets.dart';
import 'package:tadiago/annonces/models/ads_models.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/annonces/utils/tab_items.dart';
import 'package:tadiago/chat/providres/chats_provider.dart';
import 'package:tadiago/chat/utils/audio_player.dart';
import 'package:tadiago/utils/color.dart';
import 'package:collection/collection.dart';

//import 'package:tadiago/utils/constant.dart';
//myBaseUrl
class UpdateMyAds extends StatefulWidget {
  const UpdateMyAds({super.key});

  @override
  State<UpdateMyAds> createState() => _UpdateMyAdsState();
}

class _UpdateMyAdsState extends State<UpdateMyAds> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _locationSelected = "Bamako";
  String _transactionType = "Vente";

  List<Map<String, dynamic>> _subCategoriesList = [];
  List<Map<String, dynamic>> _categoriesList = [];

  List<dynamic> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isLoading = false;
  bool _isLodingTooglePose = false;
  bool _isDeleting = false;

  bool _isRecorderInitialized = false;

  //audio variable
  final AudioPlayer _audioPlayer = AudioPlayer();
  late File _audioFile = File('');
  // ignore: unused_field
  bool _showAudioPreview = false;
  String? _audioPreviewPath;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Map<String, dynamic>? _uploadedAudio;

  //Timer? _recordingTimer;

  // Ajoutez une variable pour stocker l'annonce
  Map<String, dynamic>? _ad;

  int? _cateSelected;
  int? _subCateSelected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérez l'annonce passée en argument
    _ad = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (_ad != null) {
      _initializeFormWithAdData();
    }
  }

  // Initialisez le formulaire avec les données de l'annonce
  void _initializeFormWithAdData() {
    _titleController.text = _ad!['title'] ?? '';
    _descriptionController.text = _ad!['contenu_text'] ?? '';
    _priceController.text = _ad!['price']?.toString() ?? '';
    _locationSelected = _ad!['localisation'] ?? 'Bamako';
    _transactionType = _ad!['type_de_transaction'] ?? 'Vente';
    _cateSelected = _ad!['category'];
    _subCateSelected = _ad!['sub_category'];
    _images = _ad?['images'] ?? [];
    _uploadedAudio = _ad?['ads_audio'] ?? {};
    print("audio conent: $_uploadedAudio");

    // Chargez les sous-catégories après avoir défini _cateSelected
    _getSubCate();
  }

  @override
  void initState() {
    super.initState();
    _getCategories();

    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => _position = p);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    if (!_isRecorderInitialized) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          final chatProvider =
              Provider.of<ChatsProvider>(context, listen: false);
          chatProvider.initializeRecorder();
          _isRecorderInitialized = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _getCategories() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    List<Category> categories = await adsProvider.fetchCategories();

    _categoriesList =
        categories.map((cat) => {"id": cat.id, "name": cat.name}).toList();

    setState(() {});
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

  // Fonction de mise à jour de l'annonce
  Future<void> _updatAds(int adId) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final adsProvider = Provider.of<AdsProvider>(context, listen: false);

      final success = await adsProvider.updateMyAd(
        adId: adId,
        category: _cateSelected!,
        subCategory: _subCateSelected!,
        price: _priceController.text.trim(),
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
        setState(() {
          _ad!['price'] = _priceController.text.trim();
          _ad!['title'] = _titleController.text.trim();
          _ad!['localisation'] = _locationSelected;
          _ad!['contenu_text'] = _descriptionController.text.trim();
          _ad!['type_de_transaction'] = _transactionType;
          _ad!['category'] = _cateSelected!;
          _ad!['sub_category'] = _subCateSelected!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Annonce sauvegardée avec succès !",
              style: TextStyle(color: Colors.black87),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _pickAndUploadFile(bool isImage, {bool isEdit = false}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    File file = File(pickedFile.path);

    if (!mounted) return;

    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    int? adsId = _ad!['id'];

    if (adsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : Aucun ID d'annonce trouvé !")),
      );
      setState(() => _isUploading = false);
      return;
    }

    // Détermine le type de fichier en fonction de isImage et isEdit
    String typeFile;
    if (isImage) {
      typeFile = isEdit ? "edite_image" : "image";
    } else {
      typeFile = "audio";
    }

    final result = await adsProvider.saveAdsImageOrAudio(
        file: file, adsId: adsId, typeFile: typeFile);

    if (result['success'] && result['file_url'] != null) {
      setState(() {
        if (isImage) {
          final fileId = result['file_id'];
          if (isEdit && fileId != null) {
            // Remplacer l'image existante dans la liste
            final index = _images.indexWhere((item) => item['id'] == fileId);
            if (index != -1) {
              _images[index]['image_url'] = result['file_url'];
              _images[index]['id'] = result['file_id'];
            }
          } else {
            // Ajouter une nouvelle image à la liste existante
            _images.add({
              'id': result['file_id'],
              'image_url': result['file_url'],
            });
          }
        } else {
          //Ajouter un audio
          setState(() => _uploadedAudio = {
                'id': result['file_id'],
                'audio': result['file_url'],
              });
        }
      });
    }

    setState(() => _isUploading = false);
  }

  Future<void> _deleteFile(int fileId, String typeFile) async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final result =
        await adsProvider.deleteFile(fileId: fileId, typeFile: typeFile);

    if (result['success']) {
      setState(() {
        if (typeFile == "image") {
          _images.removeWhere((file) => file['id'] == fileId);
        } else if (typeFile == "audio") {
          _uploadedAudio = null;
        }
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur lors de la suppression du fichier !")),
      );
    }
  }

  void _sendAudio() async {
    if (!mounted) return;
    setState(() => _isUploading = true);

    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    int? adsId = _ad!['id'];

    if (adsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : Aucun ID d'annonce trouvé !")),
      );
      setState(() => _isUploading = false);
      return;
    }

    final result = await adsProvider.saveAdsImageOrAudio(
      file: _audioFile,
      adsId: adsId,
      typeFile: "audio",
    );

    if (!mounted) return;

    if (result['success'] && result['file_url'] != null) {
      setState(() => _uploadedAudio = {
            'audio': result['file_url'],
            'id': result['file_id'],
          });
      debugPrint("Fichier audio uploadé avec succès : ${result['file_url']}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Erreur lors de l'upload audio : ${result['message'] ?? 'Inconnue'}")),
      );
    }

    setState(() => _isUploading = false);

    setState(() {
      _showAudioPreview = false;
      _audioPreviewPath = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _audioPlayer.stop();

    // Supprimer le fichier audio après envoi
    if (_audioPreviewPath != null) {
      final audioFile = File(_audioPreviewPath!);
      if (audioFile.existsSync()) {
        audioFile.deleteSync();
      }
    }
  }

  Future<void> _toggleRecording() async {
    final chatProvider = Provider.of<ChatsProvider>(context, listen: false);

    try {
      if (chatProvider.isRecording) {
        // Stop recording and show preview
        final audioFile = await chatProvider.stopRecording();
        //print("audio enregistré: $audioFile    isVisible: $_showAudioPreview");
        if (audioFile != null) {
          setState(() {
            _showAudioPreview = true;
            _audioPreviewPath = audioFile.path;
            _audioFile = audioFile;
          });
          // Load the audio file for preview
          //print("load the audio isVisible: $_showAudioPreview");
          await _audioPlayer.setSource(DeviceFileSource(_audioPreviewPath!));
          _duration = await _audioPlayer.getDuration() ?? Duration.zero;
        }
      } else {
        // Start recording
        //print("start recording isVisible: $_showAudioPreview");
        await chatProvider.startRecording();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
      );
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPreviewPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.stop(); // Stop pour bien réinitialiser
        await _audioPlayer.setSource(DeviceFileSource(_audioPreviewPath!));
        // Réinitialiser la position avant de jouer
        await _audioPlayer.seek(Duration.zero);
        setState(() {
          _position = Duration.zero; // Réinitialiser la position
          _isPlaying = true;
        });
        await _audioPlayer.resume();
      }
    } catch (e) {
      print("Erreur lors de la lecture audio : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la lecture audio : $e")),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _deletePreviewsAudio() {
    setState(() {
      _showAudioPreview = false;
      _audioPreviewPath = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _audioPlayer.stop();
    _audioPlayer.release();
  }

  void _updateAdsList() {
    context.read<AdsProvider>().resetPagination();

    context.read<AdsProvider>().fetchAds(
          searchQuery: null,
          subcategory: null,
        );
  }

  void _deleteMyAd() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final adsProvider = Provider.of<AdsProvider>(context, listen: false);
      final success = await adsProvider.deleteMyAd(_ad!["id"]);
      if (success) {
        //mise à jour de mes annonces
        await adsProvider.getOnlyVendorAds();
        if (!mounted) return;
        Navigator.pushNamed(context, '/update_my_ads');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce suprimée avec succès !')),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${adsProvider.error}')),
        );
      }
    } catch (error) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _toggleAd() async {
    setState(() {
      _isLodingTooglePose = true;
    });

    try {
      final adsProvider = Provider.of<AdsProvider>(context, listen: false);
      final success = await adsProvider.togglePublishedAd(
        annonceId: _ad!["id"],
        publier: _ad!["publier"],
      );
      if (!mounted) return;
      if (success) {
        _ad!["publier"] = !_ad!["publier"];
        _updateAdsList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce mise à avec succès !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${adsProvider.error}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLodingTooglePose = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Mise à jour d'annonce",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Colors.black45,
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                        color: redColor,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10))),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: const [
                      TabItems(title: "Formulaire", count: 1),
                      TabItems(title: "Images", count: 2),
                      TabItems(title: "Audio", count: 3),
                    ],
                  ),
                ),
              )),
        ),
        body: TabBarView(children: [
          _adsForm(),
          _buildImage(),
          _audioContent(),
        ]),
      ),
    );
  }

  Widget _adsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RoundedDropdownField(
              hintText: "Catégorie",
              icon: Icons.category,
              items:
                  _categoriesList.map((cat) => cat["name"] as String).toList(),
              onChanged: (value) {
                setState(() {
                  _cateSelected = int.tryParse(_categoriesList
                      .firstWhereOrNull(
                          (category) => category["name"] == value)!["id"]
                      .toString());
                  _subCateSelected = null;
                  _getSubCate();
                });
              },
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez sélectionner une catégorie'
                  : null,
              initialValue: _categoriesList.firstWhereOrNull(
                  (cat) => cat["id"] == _cateSelected)?["name"],
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
              initialValue: _subCategoriesList.firstWhereOrNull(
                  (sub) => sub["id"] == _subCateSelected)?["name"],
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
              textInputType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez entrer un prix'
                  : null,
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
              initialValue: _ad != null ? _ad!['type_de_transaction'] : null,
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
              initialValue: _ad != null ? _ad!['localisation'] : null,
            ),

            // Bouton de soumission
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_ad != null) {
                    _updatAds(_ad!['id']);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: redColor,
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Mettre à jour',
                        style: TextStyle(
                            fontSize: 15,
                            letterSpacing: 2,
                            color: Colors.white),
                      ),
              ),
            ),

            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLodingTooglePose ? null : _toggleAd,
                  child: SizedBox(
                    width: 150,
                    child: _isLodingTooglePose
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : Text(
                            _ad!["publier"]
                                ? 'Mettre en Pause'
                                : 'Mettre en Ligne',
                          ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Afficher l'AlertDialog avec showDialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text(
                            "Supprimer cette annonce",
                            style: TextStyle(color: Colors.red),
                          ),
                          content: const Text(
                              "Êtes-vous sûr de vouloir supprimer cette annonce ?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Annuler',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: Colors.green,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: _isDeleting
                                  ? null
                                  : () {
                                      _deleteMyAd();
                                    },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: _isDeleting
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : const Text(
                                      'Confirmer',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ListView.builder(
      itemCount: _images.length + 1,
      itemBuilder: (context, index) {
        if (index == _images.length) {
          return Center(
            child: ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () {
                      _pickAndUploadFile(true);
                    },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Upload Image",
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          );
        }

        return Card(
          elevation: 4, // Ombre portée
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '${_images[index]["image_url"]}',
                //'$myBaseUrl${_images[index]["image_url"]}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              "Image ${index + 1}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                index == 0 ? Icons.edit : Icons.delete,
                color: index == 0 ? Colors.blue : Colors.red,
                size: 24,
              ),
              onPressed: () {
                if (index == 0) {
                  //bouton pour editer l'image existante
                  _pickAndUploadFile(true, isEdit: true);
                } else {
                  // Fonction pour l'icône de suppression
                  _deleteFile(_images[index]['id'], "image");
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _audioPreviews() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade200,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _toggleAudioPlayback,
              ),
              Expanded(
                child: Slider(
                  //value: _position.inSeconds.toDouble(),
                  value: _position.inSeconds.toDouble().clamp(
                      0.0,
                      _duration.inSeconds > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0),
                  min: 0,
                  //max: _duration.inSeconds.toDouble(),
                  max: _duration.inSeconds > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                    setState(() => _position = position);
                  },
                ),
              ),
              Text(_formatDuration(_position)),
              const SizedBox(width: 8),
              Text(_formatDuration(_duration)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Supprimer'),
                onPressed: _deletePreviewsAudio,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Envoyer'),
                onPressed: _sendAudio,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _audioContent() {
    return Column(
      children: [
        SizedBox(
          height: 7,
        ),
        if (_uploadedAudio != null && _uploadedAudio!['audio'] != null)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: MyAudioPlayer(audioUrl: '${_uploadedAudio!['audio']}'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteFile(_uploadedAudio!['id'], "audio");
                  },
                ),
              ],
            ),
          ),
        if (_showAudioPreview) _audioPreviews(),
        Consumer<ChatsProvider>(
          builder: (context, chatProvider, child) {
            return FloatingActionButton(
              onPressed: _toggleRecording,
              backgroundColor:
                  chatProvider.isRecording ? Colors.red : Colors.blue,
              child: Icon(
                chatProvider.isRecording ? Icons.stop : Icons.mic,
                size: 30,
                color: Colors.white,
              ),
            );
          },
        ),
        Text(
          "Enregistrement audio",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
