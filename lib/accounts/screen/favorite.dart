import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/annonces/utils/ads_card.dart';
import 'package:tadiago/components/costum_app_bar.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteAds();
  }

  Future<void> _loadFavoriteAds() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    await adsProvider.getFavoriteAds();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adsProvider = Provider.of<AdsProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Mes Preferences",
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : adsProvider.favoriteAds.isEmpty
              ? Center(child: Text("Aucune annonce favorite trouvée."))
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Deux cartes par ligne
                    mainAxisSpacing: 10, // Espacement vertical entre les cartes
                    crossAxisSpacing:
                        10, // Espacement horizontal entre les cartes
                    childAspectRatio: 0.75, // Ratio largeur/hauteur des cartes
                  ),
                  itemCount: adsProvider.favoriteAds.length,
                  itemBuilder: (context, index) {
                    final ad = adsProvider.favoriteAds[index];
                    return AdsCard(
                      vendorFullName:
                          "${ad.vendor.name} ${ad.vendor.firstname}",
                      //vendorImage: "$myBaseUrl${ad.vendor.imageUrl}",
                      vendorImage: ad.vendor.imageUrl,
                      title: ad.title,
                      price: ad.price,
                      createdAt: ad.createdAt,
                      location: ad.localisation,
                      imageCount: ad.imageCount,
                      //imageUrl: "$myBaseUrl${ad.imageUrl}",
                      imageUrl: ad.imageUrl,
                      subCategoryName: ad.subCategory.name,
                      favorite: ad.favorite,
                      onTap: () {
                        Navigator.pushNamed(context, '/detail_ads', arguments: {
                          'id': ad.id,
                        });
                      },
                      onCarTap: (currentFavorite) async {
                        // Appeler toggleFavorite et retourner le nouvel état de favorite
                        final result = await adsProvider.toggleFavorite(ad.id);
                        return result
                            ? 1
                            : 0; // Retourner 1 ou 0 en fonction du résultat
                      },
                    );
                  },
                ),
    );
  }
}
