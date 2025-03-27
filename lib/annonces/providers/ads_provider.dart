import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tadiago/annonces/models/ads_models.dart';
//import 'package:tadiago/annonces/screen/save_ads.dart';
import 'package:tadiago/annonces/services/ads_services.dart';

class AdsProvider with ChangeNotifier {
  final AdsService _adsService = AdsService();

  List<Ad> _ads = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  List<Ad> get ads => _ads;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  List<Ad> _publicVendorAd = [];
  List<Ad> get publicVendorAd => _publicVendorAd;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  int? _temporaryAdId;
  int? get temporaryAdId => _temporaryAdId;

  String? _error;
  String? get error => _error;

  int _favoriteCount = 0;
  int get favoriteCount => _favoriteCount;

  List<Ad> _favoriteAds = [];
  List<Ad> get favoriteAds => _favoriteAds;

  List<int> data = List.filled(12, 0);
  List<String> labels = [];
  int totalViews = 0;

  Future<void> getPublicVendor(int? vendorID) async {
    if (_isLoading || vendorID == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Appeler le service pour récupérer les annonces du vendeur
      final annonces = await _adsService.getPublicVendor(vendorID);
      // Mettre à jour la liste des annonces du vendeur
      _publicVendorAd = annonces;
    } catch (e) {
      debugPrint("Erreur: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAds(
      {bool isNextPage = false,
      String? subcategory,
      String? searchQuery}) async {
    debugPrint('loading $isLoading  $_hasMore');
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final pagination = await _adsService.fetchAds(
        _currentPage,
        subcategory: subcategory,
        searchQuery: searchQuery,
      );

      if (isNextPage) {
        _ads.addAll(pagination.results);
      } else {
        _ads = pagination.results;
      }

      _hasMore = pagination.next != null;
      _currentPage++;
    } catch (e) {
      debugPrint("Erreur: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetPagination() {
    _ads.clear();
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  void resetAdsForPublicVendorPage() {
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  Future<AdDetails> fetchAdDetails(int id) async {
    try {
      final adDetails = await _adsService.fetchAdDetails(id);
      return adDetails;
    } catch (e) {
      debugPrint("Erreur: $e");
      rethrow;
    }
  }

  Future<List<SubCategory>> fetchAdSubcategories(int catId) async {
    try {
      final subCategory = await _adsService.fetchAdSubcategories(catId);
      return subCategory;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final categories = await _adsService.fetchCategories();
      _categories = categories;
      return categories;
    } catch (e) {
      rethrow;
    }
  }

  int? getTemporaryAdId() {
    return _temporaryAdId;
  }

  // Handle owner Ads
  // Ajout de annonce
  Future<bool> saveAds({
    required String title,
    required double price,
    required String localisation,
    required String description,
    required int category,
    required int subCategory,
    required String transactionType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AdsService.saveAds(
        title: title,
        price: price,
        localisation: localisation,
        description: description,
        category: category,
        subCategory: subCategory,
        transactionType: transactionType,
      );

      if (result['success']) {
        _temporaryAdId = result['ads_id'];
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? "Une erreur inconnue s'est produite.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Erreur inattendue : $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>?> getOnlyVendorAds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AdsService.getOnlyVendorAds();

      if (result['success']) {
        _error = null;
        notifyListeners();
        return result['ads']; // Retourne la liste des annonces
      } else {
        _error = result['message'] ?? "Une erreur inconnue s'est produite.";
        debugPrint('Erreur getOnlyVendorAds: $_error');
        notifyListeners();
        return null; // Retourne `null` en cas d'erreur
      }
    } catch (e) {
      _error = "Erreur inattendue : $e";
      debugPrint('Exception attrapée dans getOnlyVendorAds: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mise à jour d’une annonce
  Future<bool> updateMyAd({
    required int adId,
    required String title,
    required String price,
    required String localisation,
    required String description,
    required int category,
    required int subCategory,
    required String transactionType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final double? priceValue = double.tryParse(price);
      final result = await AdsService.updateMyAd(
        adId: adId,
        title: title,
        price: priceValue ?? 0.0,
        localisation: localisation,
        description: description,
        category: category,
        subCategory: subCategory,
        transactionType: transactionType,
      );

      if (result['success']) {
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? "Erreur inconnue lors de la mise à jour.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Erreur inattendue : $e";
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Suppression d’une annonce
  Future<bool> deleteMyAd(int adId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AdsService.deleteMyAd(adId);

      if (result['success']) {
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? "Erreur inconnue lors de la suppression.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Erreur inattendue : $e";
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> saveAdsImageOrAudio({
    required File file,
    required int adsId,
    required String typeFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AdsService.saveAdsImageOrAudio(
        file: file,
        adsId: adsId,
        typeFile: typeFile,
      );
      if (result['success']) {
        _error = null;
        notifyListeners();
        return {
          'success': true,
          'file_url': result['file_url'],
          'file_id': result['file_id'],
        };
      } else {
        _error = result['message'] ?? "Une erreur inconnue s'est produite.";
        notifyListeners();
        return {
          'success': false,
          'message': _error,
        };
      }
    } catch (e) {
      _error = "Erreur inattendue : $e";
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> deleteFile({
    required int fileId,
    required String typeFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AdsService.deleteFile(
        fileId: fileId,
        typeFile: typeFile,
      );
      if (result['success']) {
        _error = null;
        notifyListeners();
        return {
          'success': true,
          //'file_url': result['file_url'],
          //'file_id': result['file_id'],
        };
      } else {
        _error = result['message'] ?? "Une erreur inconnue s'est produite.";
        notifyListeners();
        return {
          'success': false,
          'message': _error,
        };
      }
    } catch (e) {
      _error = "Erreur inattendue : $e";
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendFirstMessage(String messageClient, int adsId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AdsService.sendFirstMessage(messageClient, adsId);

      if (result['success'] == true) {
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? "Erreur lors de l'envoi du message.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Erreur inattendue : $e";
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(int adId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Appeler le service pour ajouter/supprimer un favori
      final result = await AdsService.toggleFavorite(adId);

      if (result != null) {
        _favoriteCount = result['favorite_count'];
        // Mettre à jour l'état local des favoris
        final adIndex = _ads.indexWhere((ad) => ad.id == adId);
        if (adIndex != -1) {
          _ads[adIndex] =
              _ads[adIndex].copyWith(favorite: result['is_favorite'] ? 1 : 0);
        }
        return result['is_favorite']; // Retourner le nouvel état de favorite
      }
    } catch (e) {
      debugPrint('Erreur lors de la modification des favoris: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> getFavoriteCount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final count = await AdsService.getFavoriteCount();
      if (count != null) {
        _favoriteCount = count;
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getFavoriteAds() async {
    final favoriteAds = await AdsService.getFavoriteAds();
    if (favoriteAds != null) {
      _favoriteAds = favoriteAds;
      notifyListeners();
    } else {
      debugPrint('Aucune annonce favorite trouvée ou erreur de chargement.');
    }
  }

  Future<bool> togglePublishedAd({
    required int annonceId,
    required bool publier,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _adsService.togglePublishedAd(
        annonceId: annonceId,
        publier: publier,
      );

      // Vérifiez si la réponse indique un succès deleteMyAd
      if (response['status'] == 'success') {
        return true; // Succès
      } else {
        _error = response['message'] ?? 'Échec de la mise à jour de l\'annonce';
        return false; // Échec
      }
    } catch (e) {
      _error = e.toString();
      return false; // Échec
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchViews({required int year, int? annonceId}) async {
    _isLoading = true;
    notifyListeners();

    final response =
        await AdsService.getViewByMonth(year: year, annonceId: annonceId);

    if (response["success"]) {
      labels = List<String>.from(response["data"]["labels"]);
      data = List<int>.from(response["data"]["data"]);
      totalViews = data.reduce((a, b) => a + b);
      _error = null;
    } else {
      _error = response["message"];
    }

    _isLoading = false;
    notifyListeners();
  }
}
