import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:just_audio/just_audio.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/models/ads_models.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
//import 'package:tadiago/annonces/screen/vendor_public_profile.dart';
import 'package:tadiago/chat/utils/audio_player.dart';
import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/config/themes.dart';
//import 'package:tadiago/components/ad_image_gallery.dart';
//import 'package:tadiago/components/my_size.dart';
import 'package:tadiago/utils/color.dart';
import 'package:tadiago/utils/constant.dart';

//myBaseUrl
class DetailAds extends StatefulWidget {
  const DetailAds({
    super.key,
  });

  @override
  State<DetailAds> createState() => _DetailAdsState();
}

class _DetailAdsState extends State<DetailAds> {
  late Future<AdDetails>? _adDetailsFuture;
  int _adId = 0;

  String? _messageClient;

  late TapGestureRecognizer gestureRecognizer;
  bool showMore = false;
  bool _isInitialized = false;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialiser le gestureRecognizer
    gestureRecognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() {
          showMore = !showMore;
        });
      };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _adId = arguments['id'];
      final adsProvider = context.read<AdsProvider>();
      _adDetailsFuture = adsProvider.fetchAdDetails(_adId);
      _isInitialized = true;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageClient == null || _messageClient!.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un message')),
      );
      return;
    }

    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final success = await adsProvider.sendFirstMessage(_messageClient!, _adId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoyé avec succès!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adsProvider.error ?? 'Erreur inconnue')),
      );
    }
  }

  // Fonction pour afficher le BottomSheet
  void _showContactSellerBottomSheet(BuildContext context, Vendor vendor) {
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profil du vendeur
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            //NetworkImage('$myBaseUrl${vendor.imageUrl}'),
                            NetworkImage(vendor.imageUrl),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${vendor.name} ${vendor.firstname}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              vendor.description,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Champ de formulaire pour le message
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Écrivez votre message...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bouton d'envoi
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          _messageClient = _messageController.text;
                        });
                        _sendMessage();
                        _messageController.clear();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Envoyer"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    gestureRecognizer.dispose();
    _messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: CustomAppBar(
        title: "Details",
      ),
      body: FutureBuilder<AdDetails>(
        future: _adDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            final adDetails = snapshot.data!;
            final imageUrls =
                adDetails.images.map((img) => img.imageUrl).toList();

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                AdImageDetails(
                  imageUrls: imageUrls,
                  baseUrl: myBaseUrl,
                ),
                const SizedBox(height: 15),
                Text(
                  adDetails.title,
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${adDetails.price} Fcfa",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey,
                        fontFamily: "Bold",
                        fontSize: 17,
                      ),
                    ),
                    Text('/'),
                    Text(
                      "Vues: ${adDetails.viewsCount}",
                      style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: Color(0xFF3B82F6),
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          fontFamily: "Regular"),
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_searching),
                        const SizedBox(width: 8),
                        Text(
                          adDetails.localisation,
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(Icons.date_range),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(adDetails.createdAt),
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 1.0),
                      bottom: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Catégorie",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Bold"),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Transaction",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Bold"),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Mon profil",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Bold"),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              adDetails.subCategory.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                fontFamily: "Regular",
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              adDetails.typeDeTransaction,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                fontFamily: "Regular",
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/public_vendor',
                                    arguments: {
                                      'id': adDetails.vendor.id,
                                      'vendor_description':
                                          adDetails.vendor.description,
                                    });
                              },
                              child: Text(
                                "Visiter mon profil",
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF3B82F6),
                                    fontFamily: "regular"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (adDetails.adsAudio != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Description en audio",
                    style: AppTextStyles.headlineSmall,
                  ),
                  //MyAudioPlayer(audioUrl: '$myBaseUrl${adDetails.adsAudio!}'),
                  MyAudioPlayer(audioUrl: adDetails.adsAudio!),
                ],
                const SizedBox(height: 20),
                const Text(
                  "Description",
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                    children: [
                      TextSpan(
                        text: showMore
                            ? adDetails.contenuText
                            : (adDetails.contenuText.length > 100
                                ? '${adDetails.contenuText.substring(0, 100)}...'
                                : adDetails.contenuText),
                      ),
                      if (adDetails.contenuText.length >
                          100) // Ajoutez cette condition
                        TextSpan(
                          recognizer: gestureRecognizer,
                          text: showMore ? "lire moins" : " Lire plus",
                          style: const TextStyle(color: Colors.green),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _abusContaint(),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(13),
                    backgroundColor: redColor,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    _showContactSellerBottomSheet(context, adDetails.vendor);
                  },
                  child: const Text(
                    "Contactez le vendeur",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _abusContaint() {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        children: [
          Text(
            "Tadiago.com n’est pas responsable des produits proposés dans les annonces.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black54, fontSize: 14, fontFamily: "Regular"),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/signaler_abus', arguments: _adId);
            },
            icon: Icon(Icons.report, color: Colors.red),
            label: Text("Signaler un abus", style: TextStyle(color: redColor)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: redColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdImageDetails extends StatefulWidget {
  final List<String> imageUrls;
  final String baseUrl;
  const AdImageDetails(
      {super.key, required this.imageUrls, required this.baseUrl});

  @override
  State<AdImageDetails> createState() => _AdImageDetailsState();
}

class _AdImageDetailsState extends State<AdImageDetails> {
  int _selectedImageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
            //tag: widget.imageUrls[_selectedImageIndex],
            tag: "${widget.baseUrl}${widget.imageUrls[_selectedImageIndex]}",
            child: Container(
              height: 270,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  //image: NetworkImage(widget.imageUrls[_selectedImageIndex]),
                  image: NetworkImage(widget.imageUrls[_selectedImageIndex]),
                  //"${widget.baseUrl}${widget.imageUrls[_selectedImageIndex]}"),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            )),
        SizedBox(
          height: 10,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(
                widget.imageUrls.length,
                (index) => buiSmallPreview(index),
              )
            ],
          ),
        )
      ],
    );
  }

  GestureDetector buiSmallPreview(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImageIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 10),
        padding: EdgeInsets.all(8),
        height: 50,
        width: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _selectedImageIndex == index
                  ? kPrimaryColor
                  : Colors.transparent),
        ),
        child: Image.network(widget.imageUrls[index]),
        //child: Image.network('${widget.baseUrl}${widget.imageUrls[index]}'),
      ),
    );
  }
}
