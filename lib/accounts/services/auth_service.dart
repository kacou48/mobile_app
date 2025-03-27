import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tadiago/accounts/models/user_models.dart';
import 'package:tadiago/utils/constant.dart';

class AuthService {
  static const String baseUrl = myBaseUrl; // Remplacez par votre URL d'API

  static String? _accessToken;
  static String? _refreshToken;
  static User? _currentUser;
  static bool _isRefreshing = false;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    responseType: ResponseType.json,
    validateStatus: (status) {
      return status! < 500;
    },
  ));

  static String? get token => _accessToken;
  static User? get currentUser => _currentUser;

  static void _initializeInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await refreshToken();
              if (refreshed) {
                // Retry the original request with new token
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );
                opts.headers?['Authorization'] = 'Bearer $_accessToken';

                final response = await _dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );

                _isRefreshing = false;
                return handler.resolve(response);
              }
            } catch (e) {
              debugPrint('Error refreshing token: $e');
            }
            _isRefreshing = false;
          }
          return handler.next(error);
        },
      ),
    );
  }

  static Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);

    _initializeInterceptors();
  }

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');

    if (_accessToken != null) {
      _initializeInterceptors();
      // Optionally load user data here
      await _loadUserData();
    }
  }

  static Future<void> _loadUserData() async {
    try {
      final response = await _dio.get('/api/users/me/');
      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');

    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _initializeInterceptors();
    clearUser();
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/token/login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        await setTokens(
          response.data['access'],
          response.data['refresh'],
        );

        if (response.data['user'] != null) {
          try {
            _currentUser = User.fromJson(response.data['user']);
            saveUser(_currentUser!);

            return {
              'success': true,
              'user': _currentUser,
            };
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            return {
              'success': false,
              'message': 'Error parsing user data',
            };
          }
        } else {
          return await _loadUserAfterLogin();
        }
      }

      return {
        'success': false,
        'message': response.data['detail'] ?? 'An error occurred',
      };
    } on DioException catch (e) {
      debugPrint('Login DioException: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data?['detail'] ?? 'Connection error',
      };
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> _loadUserAfterLogin() async {
    try {
      final response = await _dio.get('/api/users/me/');
      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
        return {
          'success': true,
          'user': _currentUser,
        };
      }
      return {
        'success': false,
        'message': 'Error loading user data',
      };
    } catch (e) {
      debugPrint('Error loading user data after login: $e');
      return {
        'success': false,
        'message': 'Error loading user data',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String firstname,
    String? telephone,
    String? civility,
    String? status,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/token/register/',
        data: {
          'email': email,
          'name': name,
          'firstname': firstname,
          'telephone': telephone,
          'password': password,
          'password2': password,
          'civility': civility,
          'status': status ?? 'Acheteur',
        },
      );

      debugPrint('Réponse du serveur: ${response.data}');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'],
          'email': response.data['email'],
        };
      } else {
        // Gestion des erreurs de validation
        if (response.data is Map) {
          final errors = <String>[];
          response.data.forEach((key, value) {
            if (value is List) {
              errors.add('$key: ${value.join(', ')}');
            } else {
              errors.add('$key: $value');
            }
          });
          return {
            'success': false,
            'message': errors.join('\n'),
          };
        }

        return {
          'success': false,
          'message': response.data['detail'] ?? 'Erreur lors de l\'inscription'
        };
      }
    } on DioException catch (e) {
      debugPrint('DioException lors de l\'inscription: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');

      // Gestion des erreurs de validation du serveur
      if (e.response?.data is Map) {
        final errors = <String>[];
        e.response?.data.forEach((key, value) {
          if (value is List) {
            errors.add('$key: ${value.join(', ')}');
          } else {
            errors.add('$key: $value');
          }
        });
        return {
          'success': false,
          'message': errors.join('\n'),
        };
      }

      return {
        'success': false,
        'message':
            e.response?.data?['detail'] ?? 'Erreur lors de l\'inscription'
      };
    } catch (e) {
      debugPrint('Erreur inattendue lors de l\'inscription: $e');
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue lors de l\'inscription'
      };
    }
  }

  static Future<void> logout() async {
    try {
      if (_accessToken != null && _refreshToken != null) {
        await _dio.post(
          '/api/auth/token/logout/',
          data: {'refresh': _refreshToken},
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await clearTokens();
    }
  }

  static bool isAuthenticated() {
    return _accessToken != null && _currentUser != null;
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson()); // Convertir User en JSON
    await prefs.setString('user_data', userJson);
    _currentUser = user; // Met à jour la variable locale
  }

  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');

    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
    } else {
      _currentUser = null;
      debugPrint("Aucun utilisateur trouvé !");
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    _currentUser = null;
    debugPrint("Utilisateur supprimé !");
  }

  static Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    _refreshToken = prefs.getString('refresh_token');

    if (_refreshToken == null) {
      debugPrint('No refresh token available');
      return false;
    }

    try {
      final response = await _dio.post(
        '/api/auth/token/refresh/',
        data: {'refresh': _refreshToken},
      );

      if (response.statusCode == 200) {
        await setTokens(
          response.data['access'],
          _refreshToken!, // Keep existing refresh token
        );
        debugPrint('New access token obtained');
        return true;
      }

      debugPrint('Token refresh failed');
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  static Future<User> updateUser(
      int userId, Map<String, dynamic> userData) async {
    try {
      final response = await _dio.patch(
        '/api/users/container/$userId/update/',
        data: userData,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else if (response.statusCode == 401) {
        // Si le token est expiré, essayer de le rafraîchir
        bool refreshed = await refreshToken();
        if (refreshed) {
          // Réessayer la requête avec le nouveau token
          return updateUser(userId, userData);
        }
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    } catch (e) {
      debugPrint(" Erreur lors de la mise à jour de l'utilisateur: $e");
      rethrow;
    }
  }

  static Future<String?> updateProfileImage(File imageFile) async {
    try {
      String? mimeType = lookupMimeType(imageFile.path);
      var contentType = mimeType != null
          ? MediaType.parse(mimeType)
          : MediaType('image', 'jpeg');

      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          contentType: contentType,
        )
      });
      Response response = await _dio.post(
        '/api/users/container/update-profile-image/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data['image_url'];
      } else if (response.statusCode == 401) {
        // Si le token est expiré, essayer de le rafraîchir
        debugPrint("Token expiré, tentative de rafraîchissement...");
        bool refreshed = await refreshToken();
        if (refreshed) {
          // Réessayer la requête avec le nouveau token
          debugPrint("Token de rafraîchissement $_accessToken");
          return updateProfileImage(imageFile);
        } else {
          debugPrint("Échec du rafraîchissement du token.");
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour de l'image: $e");
    }
    return null;
  }

  static Future<List<String>> getVendorChoices() async {
    try {
      final response = await _dio.get('/api/vendor_choices/');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['choices']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException during vendor choices retrieval: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during vendor choices retrieval: $e');
      rethrow;
    }
  }

  static Future<User?> fetchCurrentUser() async {
    try {
      final response = await _dio.get('/api/users/me/');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getVerifyCode(
      Map<String, dynamic> userEmail) async {
    try {
      final response = await _dio.post(
        '/api/auth/token/get_or_resent_code/', // Correct endpoint
        data: userEmail,
      );

      if (response.statusCode == 200) {
        return {
          'success': true, // Add a success flag
          'message': response.data['message'],
          'verification_code':
              response.data['verification_code'], // Include the code
        };
      } else {
        // Improved error handling
        final errorData = response.data;
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'An error occurred';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage, // Include the error message
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException during processing: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      rethrow; // Re-throw to be caught in the provider
    } catch (e) {
      debugPrint('Unexpected error during processing: $e');
      rethrow; // Re-throw to be caught in the provider
    }
  }

  static Future<Map<String, dynamic>> toActiveUser(
      Map<String, dynamic> userEmail) async {
    try {
      final response = await _dio.post(
        '/api/auth/token/active_user/', // Correct endpoint
        data: userEmail,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
        };
      } else {
        // Improved error handling
        final errorData = response.data;
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'An error occurred';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage, // Include the error message
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException during processing: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      rethrow; // Re-throw to be caught in the provider
    } catch (e) {
      debugPrint('Unexpected error during processing: $e');
      rethrow; // Re-throw to be caught in the provider
    }
  }

  //pour ios
  static final clientID =
      "338376929711-sqillong953kikrgsdhtmfdvbha4nb8m.apps.googleusercontent.com";

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS ? clientID : null,
    scopes: [
      'email',
    ],
  );

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Connexion annulée par l’utilisateur'
        };
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint("googleAuth $googleAuth");
      debugPrint("idToken $idToken");
      if (idToken == null) {
        return {'success': false, 'message': 'Impossible d’obtenir l’ID Token'};
      }

      // Envoyer le token à Django pour l'authentification
      final response = await Dio().post(
        '/api/auth/google-login/',
        data: {'id_token': idToken},
      );

      if (response.statusCode == 200) {
        await setTokens(response.data['access'], response.data['refresh']);

        return {
          'success': true,
          'user': response.data['user'],
        };
      }

      return {
        'success': false,
        'message': response.data['detail'] ?? 'Erreur inconnue'
      };
    } catch (e) {
      debugPrint('Erreur google login: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // pass word forgot

  static Future<Map<String, dynamic>> sendResetPassWord(
      Map<String, dynamic> userEmail) async {
    try {
      final response = await _dio.post(
        '/api/auth/token/reset_password/', // Correct endpoint
        data: userEmail,
      );

      if (response.statusCode == 200) {
        return {
          'success': true, // Add a success flag
          'message': response.data['message'],
          'jwt_token_password': response.data['jwt_token_password'],
        };
      } else {
        // Improved error handling
        final errorData = response.data;
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'An error occurred';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage, // Include the error message
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException during processing: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      rethrow; // Re-throw to be caught in the provider
    } catch (e) {
      debugPrint('Unexpected error during processing: $e');
      rethrow; // Re-throw to be caught in the provider
    }
  }

  static Future<Map<String, dynamic>> sendResetPassWordVerify(
      Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(
        '/api/auth/token/reset_password_verify/',
        data: userData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true, // Add a success flag
          'message': response.data['message'],
        };
      } else if (response.statusCode == 400) {
        return {
          "success": false,
          "message": response.data['error'],
        };
      } else {
        // Improved error handling
        final errorData = response.data;
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'An error occurred';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage, // Include the error message
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException during processing: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      rethrow; // Re-throw to be caught in the provider
    } catch (e) {
      debugPrint('Unexpected error during processing: $e');
      rethrow; // Re-throw to be caught in the provider
    }
  }

  static Future<Map<String, dynamic>> sendNewPassWord(
      Map<String, dynamic> userPassword) async {
    try {
      final response = await _dio.post(
        '/api/auth/token/change_password/',
        data: userPassword,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      } else if (response.statusCode == 400) {
        return {"success": false, "message": response.data['error']};
      } else {
        // Improved error handling
        final errorData = response.data;
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'An error occurred';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage, // Include the error message
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException during processing: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      rethrow; // Re-throw to be caught in the provider
    } catch (e) {
      debugPrint('Unexpected error during processing: $e');
      rethrow; // Re-throw to be caught in the provider
    }
  }

  // Méthode pour supprimer le compte utilisateur logout
  static Future<Map<String, dynamic>> deleteMyAccount(int userId) async {
    try {
      final response = await _dio.delete(
        '/api/user/container/$userId/delete/',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );
      debugPrint("eeee $response");
      if (response.statusCode == 204) {
        return {"success": true, "message": "Compte supprimé avec succès."};
      } else if (response.statusCode == 403) {
        return {
          "success": false,
          "message": "Vous n'êtes pas autorisé à supprimer ce compte."
        };
      } else if (response.statusCode == 404) {
        return {"success": false, "message": "Utilisateur non trouvé."};
      } else {
        return {
          "success": false,
          "message": "Erreur lors de la suppression du compte."
        };
      }
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data["detail"] ?? "Erreur inconnue."
      };
    } catch (e) {
      debugPrint('error $e');
      return {"success": false, "message": "Erreur inatendue: $e"};
    }
  }
}
