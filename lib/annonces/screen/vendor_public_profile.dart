import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/config/themes.dart';

class VendorPublicProfile extends StatefulWidget {
  //final int vendorId;
  const VendorPublicProfile({super.key});

  @override
  State<VendorPublicProfile> createState() => _VendorPublicProfileState();
}

class _VendorPublicProfileState extends State<VendorPublicProfile> {
  //bool _isInitializedPage = false;
  int? _vendorID;
  late TapGestureRecognizer gestureRecognizer;
  bool showMore = false;
  String _description = '';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVendorAds();
    });
  }

  void _fetchVendorAds() async {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final newVendorID = arguments['id'];
    _description = arguments['vendor_description'];
    // Si l'ID change, on recharge les annonces
    if (_vendorID != newVendorID) {
      debugPrint('Chargement des nouvelles annonces...');
      _vendorID = newVendorID;

      final adsProvider = context.read<AdsProvider>();
      await adsProvider.getPublicVendor(_vendorID);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Profil du vendeur",
      ),
      body: Consumer<AdsProvider>(
        builder: (context, adsProvider, child) {
          if ((adsProvider.publicVendorAd.isEmpty && adsProvider.isLoading)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adsProvider.publicVendorAd.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Aucune annonce disponible"),
                ],
              ),
            );
          }

          final vendor = adsProvider.publicVendorAd.first.vendor;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section Informations du Vendeur
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(vendor.imageUrl),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "${vendor.name} ${vendor.firstname}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Dernière connexion: ${vendor.getConnectionDuration}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Inscris depuis le ${DateFormat('dd/MM/yyyy').format(vendor.birthDate)}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Section Annonces du Vendeur
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Annonces disponible',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: adsProvider.publicVendorAd.length,
                    itemBuilder: (context, index) {
                      final ad = adsProvider.publicVendorAd[index];
                      return Container(
                        width: 150, // Largeur fixe pour chaque annonce
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/detail_ads',
                                arguments: {'id': ad.id});
                          },
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ad.imageUrl != null)
                                  Image.network(
                                    ad.imageUrl!,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ad.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ad.localisation,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${ad.price} FCFA',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                if (_description != '')
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    ? _description
                                    : (_description.length > 100
                                        ? '${_description.substring(0, 100)}...'
                                        : _description),
                              ),
                              if (_description.length >
                                  100) // Ajoutez cette condition
                                TextSpan(
                                  recognizer: gestureRecognizer,
                                  text: showMore ? "lire moins" : " Lire plus",
                                  style: const TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
