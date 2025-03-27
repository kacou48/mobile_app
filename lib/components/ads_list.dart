import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/services/auth_service.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/annonces/utils/ads_card.dart';

class AdsList extends StatefulWidget {
  const AdsList({super.key});

  @override
  State<AdsList> createState() => _AdsListState();
}

class _AdsListState extends State<AdsList> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  Future<void> fetchAdsWithRetry({int maxRetries = 7}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        if (!mounted) return;
        final adsProvider = Provider.of<AdsProvider>(context, listen: false);
        await adsProvider.fetchAds();

        // Vérifier si nous avons reçu des données
        if (adsProvider.ads.isNotEmpty) {
          if (!mounted) return;
          await adsProvider.getFavoriteCount();
          debugPrint("getFavoriteCount réussi !");
          return; // Sortir seulement si nous avons des données
        }

        // Si la liste est vide, on continue d'essayer
        attempt++;
        debugPrint("Liste vide, nouvelle tentative dans 2 secondes");
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        attempt++;
        debugPrint("resultat dechoue annonce : ${e.toString()}");

        debugPrint("Tentative $attempt échouée : $e");

        // Si l'erreur est liée au token, essayer de le rafraîchir
        if (e.toString().contains("token_not_valid")) {
          debugPrint("Token invalide, tentative de rafraîchissement");
          final refreshed = await AuthService.refreshToken();
          if (refreshed) {
            debugPrint("Token rafraîchi avec succès");
            continue; // Continuer avec le nouveau token
          }
        }

        await Future.delayed(const Duration(seconds: 2));
      }
    }
    debugPrint("Échec total après $maxRetries tentatives");
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      Future.microtask(() => fetchAdsWithRetry());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      context.read<AdsProvider>().fetchAds(isNextPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdsProvider>(
      builder: (context, adsProvider, child) {
        if (!_isInitialized ||
            (adsProvider.ads.isEmpty && adsProvider.isLoading)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adsProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(adsProvider.error ??
                    "Échec du chargement des annonces. Veuillez réessayer."),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitialized = false;
                      Future.microtask(() => fetchAdsWithRetry());
                    });
                  },
                  child: const Text("Réessayer"),
                ),
              ],
            ),
          );
        }

        if (adsProvider.ads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Aucune annonce disponible"),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitialized = false;
                      Future.microtask(() => fetchAdsWithRetry());
                    });
                  },
                  child: const Text("Rafraîchir"),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: adsProvider.ads.length + (adsProvider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < adsProvider.ads.length) {
              final ad = adsProvider.ads[index];
              return AdsCard(
                vendorFullName: "${ad.vendor.name} ${ad.vendor.firstname}",
                vendorImage: ad.vendor.imageUrl,
                title: ad.title,
                price: ad.price,
                createdAt: ad.createdAt,
                location: ad.localisation,
                imageCount: ad.imageCount,
                imageUrl: ad.imageUrl,
                subCategoryName: ad.subCategory.name,
                favorite: ad.favorite,
                onTap: () {
                  Navigator.pushNamed(context, '/detail_ads',
                      arguments: {'id': ad.id});
                },
                onCarTap: (currentFavorite) async {
                  final result = await adsProvider.toggleFavorite(ad.id);
                  return result ? 1 : 0;
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }
}
