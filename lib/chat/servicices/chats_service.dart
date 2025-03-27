import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tadiago/accounts/services/auth_service.dart';
import 'package:tadiago/chat/models/chats_models.dart';
import 'package:tadiago/utils/constant.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatsService {
  static const String baseUrl = myBaseUrl;
  int _reconnectAttempts = 0;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    responseType: ResponseType.json,
    validateStatus: (status) {
      return status! < 500;
    },
  ));

  // Méthode pour récupérer les interactions de l'utilisateur
  static Future<List<Map<String, dynamic>>> getUserInteractions() async {
    try {
      // Récupérer le token d'accès
      final String? accessToken = AuthService.token;

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Faire la requête avec le token actuel
      final response = await _dio.get(
        '/api/chat/user_interactions/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.statusCode == 401) {
        // Si le token est invalide, rafraîchir le token
        bool refreshed = await AuthService.refreshToken();
        if (refreshed) {
          // Récupérer le nouveau token
          final String? newAccessToken = AuthService.token;

          if (newAccessToken == null) {
            throw Exception('Failed to refresh token');
          }

          // Réessayer la requête avec le nouveau token
          final retryResponse = await _dio.get(
            '/api/chat/user_interactions/',
            options:
                Options(headers: {'Authorization': 'Bearer $newAccessToken'}),
          );

          if (retryResponse.statusCode == 200) {
            return List<Map<String, dynamic>>.from(retryResponse.data);
          } else {
            throw Exception(
                'Failed to load user interactions after token refresh');
          }
        } else {
          throw Exception('Failed to refresh token');
        }
      } else {
        throw Exception('Failed to load user interactions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  IOWebSocketChannel? _channelNotif;
  IOWebSocketChannel? _channelChat;

  bool _isConnectingNotif = false;
  bool _isConnectingChat = false;

  final _messageStreamController = StreamController<MessageModel>.broadcast();

  Stream<MessageModel> get messageStream => _messageStreamController.stream;

  void connectToNotify(String authToken, Function(int) onUnreadCountUpdated) {
    if (_isConnectingNotif || _channelNotif != null) return;

    _isConnectingNotif = true;
    try {
      _channelNotif = IOWebSocketChannel.connect(
        'wss://www.tadiago.com/ws/notifications/',
        headers: {
          'Authorization': 'Bearer $authToken',
          'Origin': baseUrl,
          'Sec-WebSocket-Protocol': 'wss',
        },
        pingInterval: const Duration(seconds: 30),
      );

      debugPrint('Notification WebSocket connecté !');

      _channelNotif!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            if (data['type'] == 'send_notification') {
              debugPrint("Nouveau count: ${data['unread_count']}");
              onUnreadCountUpdated(data['unread_count'] as int);
            }
          } catch (e) {
            debugPrint("Erreur parsing message: $e");
          }
        },
        onError: (error) =>
            _handleNotifError(error, authToken, onUnreadCountUpdated),
        onDone: () => _handleNotifClose(authToken, onUnreadCountUpdated),
      );
    } catch (e) {
      debugPrint("Erreur de connexion WebSocket Notification: $e");
      _reconnectNotif(authToken, onUnreadCountUpdated);
    } finally {
      _isConnectingNotif = false;
    }
  }

  void _handleNotifError(error, String authToken, Function(int) callback) {
    debugPrint("Erreur WebSocket Notification: $error");
    _reconnectNotif(authToken, callback);
  }

  void _handleNotifClose(String authToken, Function(int) callback) {
    debugPrint("Connexion WebSocket Notification fermée");
    _reconnectNotif(authToken, callback);
  }

  void _reconnectNotif(String authToken, Function(int) callback) {
    disconnectNotifyWebSocket();
    Future.delayed(const Duration(seconds: 5), () {
      connectToNotify(authToken, callback);
    });
  }

  void disconnectNotifyWebSocket() {
    if (_channelNotif != null) {
      debugPrint('Déconnexion WebSocket Notification...');
      _channelNotif!.sink.close(status.goingAway);
      _channelNotif = null;
    }
  }

  //Ouvrir la connexion WebSocket pour le Chat
  String _buildWebSocketUrl(int annonceId, String roomName) {
    final cleanRoomName = roomName.replaceAll(RegExp(r'[/#]+$'), '');
    return 'wss://www.tadiago.com/ws/messages/$annonceId/$cleanRoomName/';
  }

  // Connect to WebSocket Connexion WebSocket Chat fermée
  void connectToChat(int annonceId, String roomName, String authToken) {
    if (_isConnectingChat || _channelChat != null) return;

    _isConnectingChat = true;
    _reconnectAttempts = 0; // Réinitialiser quand la connexion réussit
    final wsUrl = _buildWebSocketUrl(annonceId, roomName);
    debugPrint('Connexion au WebSocket Chat: $wsUrl');

    try {
      // Fermer l'ancienne connexion si elle existe
      _channelChat?.sink.close();

      _channelChat = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Origin': baseUrl,
          'Sec-WebSocket-Protocol': 'wss',
        },
      );

      debugPrint('WebSocket Chat connecté !');

      // Quand la connexion réussit
      _isConnectingChat = false;
      _reconnectAttempts = 0;

      _channelChat!.stream.listen(
        (dynamic message) {
          try {
            final data = jsonDecode(message);
            _messageStreamController.add(MessageModel.fromJson(data));
          } catch (e) {
            debugPrint('Erreur parsing message Chat: $e');
          }
        },
        onError: (error) =>
            _handleChatError(error, annonceId, roomName, authToken),
        onDone: () => _handleChatClose(annonceId, roomName, authToken),
      );
    } catch (e) {
      debugPrint('Erreur de connexion WebSocket Chat: $e');
      _isConnectingChat = false;
      _reconnectChat(annonceId, roomName, authToken);
    } finally {
      _isConnectingChat = false;
    }
  }

  void _handleChatError(
      error, int annonceId, String roomName, String authToken) {
    debugPrint("Erreur WebSocket Chat: $error");
    _reconnectChat(annonceId, roomName, authToken);
  }

  void _handleChatClose(int annonceId, String roomName, String authToken) {
    debugPrint("Connexion WebSocket Chat fermée");
    _reconnectChat(annonceId, roomName, authToken);
  }

  void _reconnectChat(int annonceId, String roomName, String authToken) {
    if (_isConnectingChat) return;

    disconnectChatWebSocket();

    // Délai progressif avec un maximum de 10 secondes
    final delay = Duration(seconds: _reconnectAttempts.clamp(1, 10));
    debugPrint(
        'Tentative de reconnexion #$_reconnectAttempts dans ${delay.inSeconds}s');

    Future.delayed(delay, () {
      if (!_isConnectingChat) {
        _reconnectAttempts++;
        connectToChat(annonceId, roomName, authToken);
      }
    });
  }

  void disconnectChatWebSocket() {
    if (_channelChat != null) {
      debugPrint('Déconnexion WebSocket Chat...');
      _channelChat!.sink.close(1000);
      _channelChat = null;
    }
  }

  // Send text message
  void sendTextMessage({
    required String message,
    required String roomName,
    required int senderId,
    required String senderName,
    String? senderImageUrl,
  }) {
    if (_channelChat == null) {
      debugPrint('WebSocket not connected');
      return;
    }

    final data = {
      'message': message,
      'room_name': roomName,
      'sender_id': senderId,
      'sender': senderName,
      'sender_url': senderImageUrl,
    };

    _channelChat!.sink.add(jsonEncode(data));
  }

  // Send file (image or audio everythings goes well with image sending)
  Future<void> sendFile({
    required File file,
    required String fileType, // 'image' or 'audio'
    required String roomName,
    required int senderId,
  }) async {
    if (_channelChat == null) {
      debugPrint('WebSocket not connected');
      return;
    }

    try {
      // Read file as bytes
      final bytes = await file.readAsBytes();

      // Convert to base64
      final base64File = base64Encode(bytes);

      // Send via WebSocket
      final data = {
        'file': base64File,
        'file_type': fileType,
        'room_name': roomName,
        'sender_id': senderId,
      };

      _channelChat!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('Error sending file: $e');
    }
  }

  // Get chat history
  Future<List<MessageModel>> getChatHistory(
      String roomName, String authToken) async {
    try {
      final response = await _dio.post(
        '/api/chat/history/$roomName/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting chat history: $e');
      return [];
    }
  }

  // Dispose resources service
  void dispose() {
    disconnectChatWebSocket();
    disconnectNotifyWebSocket();
    _messageStreamController.close();
  }
}
