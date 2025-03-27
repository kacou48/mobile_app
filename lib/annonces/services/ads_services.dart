import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tadiago/accounts/services/auth_service.dart';
import 'package:tadiago/annonces/models/ads_models.dart';
import 'package:tadiago/annonces/utils/devise.dart';
import 'package:tadiago/utils/constant.dart';

class AdsService {
  static const String baseUrl = myBaseUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    responseType: ResponseType.json,
    validateStatus: (status) {
      return status! < 500;
    },
  ));

  Future<List<Ad>> getPublicVendor(int vendorID) async {
    try {
      final String? accessToken = AuthService.token;
      if (accessToken == null) {
        throw Exception("Erreur d'authentification");
      }

      final response = await _dio.get(
        "$baseUrl/api/ads_data/annonces_public_vendeur/",
        queryParameters: {"vendor_id": vendorID},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        // Supposons que la réponse est une liste d'annonces
        final Map<String, dynamic> data = response.data;
        debugPrint('response: $data');
        final List<dynamic> annoncesData = data['results'];
        return annoncesData.map((json) => Ad.fromJson(json)).toList();
      } else {
        throw Exception(
            "Erreur lors du chargement des annonces: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Erreur réseau: ${e.message}");
    }
  }

  Future<Pagination> fetchAds(int page,
      {String? subcategory, String? searchQuery}) async {
    // Add subcategory parameter
    try {
      //final queryParams = {"page": page};
      final queryParams = <String, dynamic>{"page": page};
      if (subcategory != null) {
        queryParams['sub_category'] =
            subcategory; // Use correct query parameter name header
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery; // Paramètre pour la recherche
      }

      final String? accessToken = AuthService.token;

      if (accessToken == null) {
        throw Exception("erreur d'autentification");
      }

      final response = await _dio.get(
        "$baseUrl/api/ads_data/annonces/",
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.statusCode == 200) {
        return Pagination.fromJson(response.data);
      } else {
        throw Exception(
            "Erreur lors du chargement des annonces: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Erreur réseau: ${e.message}");
    }
  }

  Future<AdDetails> fetchAdDetails(int id) async {
    try {
      final headers = await getDeviceHeaders();
      final response = await _dio.get(
        "$baseUrl/api/ads_data/annonces/$id/",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        debugPrint("response $response.data");
        return AdDetails.fromJson(response.data);
      } else {
        throw Exception(
            "Erreur lors du chargement des détails de l'annonce: ${response.statusCode}");
      }
    } on DioException catch (e) {
      debugPrint("Erreur réseau: ${e.message}");
      throw Exception("Erreur réseau: ${e.message}");
    }
  }

  Future<List<SubCategory>> fetchAdSubcategories(int catId) async {
    try {
      final response =
          await _dio.get("$baseUrl/api/ads_data/get-subcategories/$catId/");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        return jsonData.map((json) => SubCategory.fromJson(json)).toList();
      } else {
        throw Exception(
            "Erreur lors du chargement des sous-catégories: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Erreur réseau: ${e.message}");
    }
  }

  Future<List<Category>> fetchCategories() async {
    final response = await _dio.get("$baseUrl/api/ads_data/get_categories/");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = response.data;
      //return data.map((json) => Category.fromJson(json)).toList();
      return jsonData.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement des catégories');
    }
  }

  // handle own ads crud
  // Ajouter une annonce
  static const String _adsEndpoint = '/api/users/container/own_ads/';

  static Future<Map<String, dynamic>> saveAds({
    required String title,
    required double price,
    required String localisation,
    required String description,
    required int category,
    required int subCategory,
    required String transactionType,
  }) async {
    return _attemptSaveAds(
      title: title,
      price: price,
      localisation: localisation,
      description: description,
      category: category,
      subCategory: subCategory,
      transactionType: transactionType,
      retryOnUnauthorized: true, // Permet un rafraîchissement du token
    );
  }

  static Future<Map<String, dynamic>> _attemptSaveAds({
    required String title,
    required double price,
    required String localisation,
    required String description,
    required int category,
    required int subCategory,
    required String transactionType,
    required bool retryOnUnauthorized, // Pour éviter la récursion infinie
  }) async {
    final String? accessToken = AuthService.token;

    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié. Veuillez vous reconnecter.',
      };
    }

    try {
      final response = await _dio.post(
        _adsEndpoint,
        data: {
          'title': title,
          'price': price,
          'localisation': localisation,
          'contenu': description,
          'category': category,
          'sub_category': subCategory,
          'type_de_transaction': transactionType,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      //debugPrint('Réponse du serveur: ${response.data}');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'ads_id': response.data['id'],
        };
      } else if (response.statusCode == 401 && retryOnUnauthorized) {
        debugPrint('Token expiré, tentative de rafraîchissement...');

        bool refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return _attemptSaveAds(
            title: title,
            price: price,
            localisation: localisation,
            description: description,
            category: category,
            subCategory: subCategory,
            transactionType: transactionType,
            retryOnUnauthorized: false, // Évite une boucle infinie en casd'éch
          );
        } else {
          return {
            'success': false,
            'message':
                'Échec du rafraîchissement du token. Veuillez vous reconnecter.',
          };
        }
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(response.data),
        };
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');

      return {
        'success': false,
        'message': _extractErrorMessage(e.response?.data),
      };
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue. Veuillez réessayer.',
      };
    }
  }

  static Future<Map<String, dynamic>> getOnlyVendorAds() async {
    final String? accessToken = AuthService.token;

    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié. Veuillez vous reconnecter.',
      };
    }

    try {
      final response = await _dio.get(
        _adsEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      //debugPrint('Réponse du serveur: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'ads': response.data["results"], // Liste des annonces du vendeur
        };
      } else if (response.statusCode == 401) {
        debugPrint('Token expiré, tentative de rafraîchissement...');

        bool refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return getOnlyVendorAds(); // Relance la requête après rafraîchissement
        } else {
          return {
            'success': false,
            'message':
                'Échec du rafraîchissement du token. Veuillez vous reconnecter.',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Une erreur est survenue lors de la récupération des annonces.',
        };
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      return {
        'success': false,
        'message': 'Erreur réseau. Veuillez vérifier votre connexion.',
      };
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue. Veuillez réessayer.',
      };
    }
  }

  /// Met à jour une annonce avec gestion du token expiré
  static Future<Map<String, dynamic>> updateMyAd({
    required int adId,
    required String title,
    required double price,
    required String localisation,
    required String description,
    required int category,
    required int subCategory,
    required String transactionType,
    bool retried = false,
  }) async {
    final String? accessToken = AuthService.token;

    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié. Veuillez vous reconnecter.',
      };
    }

    try {
      final response = await _dio.put(
        '$_adsEndpoint$adId/',
        data: {
          'title': title,
          'price': price,
          'localisation': localisation,
          'contenu': description,
          'category': category,
          'sub_category': subCategory,
          'type_de_transaction': transactionType,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Annonce mise à jour avec succès'};
      } else if (response.statusCode == 401 && !retried) {
        debugPrint('Token expiré, tentative de rafraîchissement...');

        bool refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return updateMyAd(
            adId: adId,
            title: title,
            price: price,
            localisation: localisation,
            description: description,
            category: category,
            subCategory: subCategory,
            transactionType: transactionType,
            retried: true,
          );
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur lors de la mise à jour'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Supprime une annonce avec gestion du token expiré
  static Future<Map<String, dynamic>> deleteMyAd(int adId,
      {bool retried = false}) async {
    final String? accessToken = AuthService.token;

    if (accessToken == null) {
      return {'success': false, 'message': 'Utilisateur non authentifié'};
    }

    try {
      final response = await _dio.delete(
        '$_adsEndpoint$adId/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 204) {
        return {'success': true, 'message': 'Annonce supprimée avec succès'};
      } else if (response.statusCode == 401 && !retried) {
        debugPrint('Token expiré, tentative de rafraîchissement...');
        bool refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return deleteMyAd(adId, retried: true);
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur lors de la suppression'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteFile({
    required int fileId,
    required String typeFile,
  }) async {
    final String? accessToken = AuthService.token;
    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié. Veuillez vous reconnecter.',
      };
    }

    try {
      // FormData formData = FormData.fromMap({
      //   'file_id': fileId,
      //   'type_file': typeFile,
      // });

      final response = await _dio.delete(
        '/api/users/container/delete_file/',
        data: {
          'file_id': fileId,
          'type_file': typeFile,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
        }),
      );

      debugPrint('Réponse du serveur: ${response.data}');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'message': response.data['message']};
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(response.data),
        };
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');

      return {
        'success': false,
        'message': _extractErrorMessage(e.response?.data),
      };
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue. Veuillez réessayer.',
      };
    }
  }

  static Future<Map<String, dynamic>> saveAdsImageOrAudio({
    required File file,
    required int adsId,
    required String typeFile, // "image" ou "audio"
  }) async {
    final String? accessToken = AuthService.token;

    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié. Veuillez vous reconnecter.',
      };
    }

    try {
      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'ads_id': adsId,
        'type_file': typeFile,
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _dio.post(
        '/api/users/container/upload_file/',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          "Content-Type": "multipart/form-data"
        }),
      );

      debugPrint('Réponse du serveur: ${response.data}');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'file_url': response.data['file_url'],
          'file_id': response.data['file_id'],
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(response.data),
        };
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');

      return {
        'success': false,
        'message': _extractErrorMessage(e.response?.data),
      };
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue. Veuillez réessayer.',
      };
    }
  }

  /// Fonction pour extraire les messages d'erreur du serveur
  static String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.add('$key: ${value.join(', ')}');
        } else {
          errors.add('$key: $value');
        }
      });
      return errors.isNotEmpty ? errors.join('\n') : 'Erreur inconnue';
    } else if (data is String) {
      return data;
    }
    return 'Erreur inconnue';
  }

  //envoi de premier message du client
  static Future<Map<String, dynamic>> sendFirstMessage(
    String messageClient,
    int adsId, {
    bool retried = false,
  }) async {
    final String? accessToken = AuthService.token;
    if (accessToken == null) {
      return {'success': false, 'message': 'Utilisateur non authentifié'};
    }

    try {
      final response = await _dio.post(
        '/api/chat/first_message/',
        data: {"message": messageClient, "annonce_id": adsId},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode == 201) {
        // Succès : message envoyé
        return {
          'success': true,
          'message': 'Message envoyé avec succès',
          'data': response.data, // Inclure les données renvoyées par l'API
        };
      } else if (response.statusCode == 401 && !retried) {
        // Token expiré, tentative de rafraîchissement
        debugPrint('Token expiré, tentative de rafraîchissement...');
        bool refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return sendFirstMessage(messageClient, adsId, retried: true);
        }
      }

      // Gestion des erreurs spécifiques
      return {
        'success': false,
        'message':
            response.data['message'] ?? "Erreur lors de l'envoi du message",
      };
    } on DioException catch (e) {
      // Gestion des erreurs réseau ou serveur
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur réseau: ${e.message}',
      };
    } catch (e) {
      // Erreur inattendue
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }

  static Future<int?> getFavoriteCount() async {
    final String? accessToken = AuthService.token;
    if (accessToken == null) {
      return null;
    }

    try {
      final response = await _dio.get(
        '/api/users/container/favorites_count/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data['favorite_count'];
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du nombre de favoris: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> toggleFavorite(int annonceId) async {
    final String? accessToken = AuthService.token;
    if (accessToken == null) {
      return null;
    }

    try {
      final response = await _dio.post(
        '/api/users/container/favorites_toggle/',
        data: {'annonce_id': annonceId},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Erreur lors de la modification des favoris: $e');
    }
    return null;
  }

  static Future<List<Ad>?> getFavoriteAds() async {
    final String? accessToken = AuthService.token;
    if (accessToken == null) {
      return null;
    }

    try {
      final response = await _dio.get(
        '/api/ads_data/get_favorites/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        // Convertir la réponse JSON en une liste d'objets Ad
        final List<dynamic> data = response.data;
        return data.map((json) => Ad.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des favoris: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> togglePublishedAd({
    required int annonceId,
    required bool publier,
  }) async {
    final String? accessToken = AuthService.token;
    if (accessToken == null) {
      throw Exception('access token invalide');
    }
    try {
      final response = await _dio.post(
        '/api/ads_data/toogle_published_ad/',
        data: {'annonce_id': annonceId, 'publier': publier},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour : $e');
      rethrow; // Propager l'erreur pour la gestion dans le provider
    }
    throw Exception('Échec de la mise à jour de l\'annonce');
  }

  static Future<Map<String, dynamic>> getViewByMonth(
      {required int year, int? annonceId}) async {
    final String? accessToken = AuthService.token;

    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié. Veuillez vous reconnecter.',
      };
    }

    try {
      final response = await _dio.get(
        "/api/users/container/vues-par-mois/",
        queryParameters: {
          "year": year,
          if (annonceId != null) "annonce_id": annonceId,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return {"success": true, "data": response.data};
      } else {
        return {"success": false, "message": response.data["error"]};
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      return {
        'success': false,
        'message': 'Erreur réseau. Veuillez vérifier votre connexion.',
      };
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue. Veuillez réessayer.',
      };
    }
  }
}
