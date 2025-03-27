import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/chat/models/chats_models.dart';
import 'package:tadiago/chat/servicices/chats_service.dart';

class ChatsProvider with ChangeNotifier {
  // ignore: unused_field
  final ChatsService _chatService = ChatsService();

  String? _chatToken;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isNotifLoading = false;
  bool get isNotifLoading => _isNotifLoading;

  List<Map<String, dynamic>> _userInteractions = [];
  List<Map<String, dynamic>> get userInteractions => _userInteractions;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _unreadMessagesCount = 0;
  int get unreadMessagesCount => _unreadMessagesCount;

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  // Current chat room info
  String? _currentRoomName;
  // ignore: unused_field
  int? _currentAnnonceId;
  bool _isConnectedForNotify = false;

  // Ajoutez cette variable pour garder la trace de l'abonnement
  StreamSubscription<MessageModel>? _messageSubscription;

  // Audio recording
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  String? _recordingPath;
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<void> _loadChatToken() async {
    try {
      final authProvider = AuthProvider();
      _chatToken = await authProvider.insistToGetToken();
      debugPrint("Chat Token récupéré");
    } catch (e) {
      debugPrint("Erreur lors de la récupération du token : $e");
      _chatToken = null;
    }
  }

  // Méthode pour charger les interactions de l'utilisateur
  Future<void> getUserInteractions() async {
    if (_isNotifLoading) return;
    _isNotifLoading = true;
    notifyListeners();

    try {
      debugPrint("page relancé");
      // Charger les nouvelles interactions dans une liste temporaire
      final List<Map<String, dynamic>> newInteractions =
          await ChatsService.getUserInteractions();
      _userInteractions = newInteractions;
      //debugPrint("inter: $_userInteractions");

      if (_userInteractions.isEmpty) {
        _errorMessage = 'Aucun utilisateur trouvé';
      } else {
        _errorMessage =
            null; //Réinitialise l'erreur après une récupération réussie
        _unreadMessagesCount = _userInteractions
            .where((interaction) => interaction['unread_count'] != null)
            .map((interaction) => interaction['unread_count'] as int)
            .fold(0, (a, b) => a + b);
      }
    } catch (e) {
      debugPrint('Error loading user interactions: $e');
      _errorMessage = e.toString();
    } finally {
      _isNotifLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _setError('Microphone permission not granted');
      return;
    }

    await _audioRecorder.openRecorder();
    _isRecorderInitialized = true;
  }

  //Notification websocket
  void connectToNotify() async {
    debugPrint("lancement de la connexion notification");
    if (_isConnectedForNotify) return;

    try {
      await _loadChatToken();
      if (_chatToken == null) {
        throw Exception("Token is null, unable to initialize notification.");
      }
      _chatService.connectToNotify(_chatToken!, (message) {
        // Quand un nouveau message arrive, recharge les interactions
        getUserInteractions();
      });
      _isConnectedForNotify = true;
    } catch (e) {
      debugPrint('Failed to initialize notification: $e');
    }
  }

  // Initialize chat for a specific room connectToWebSocket
  Future<void> initializeChat({
    required int annonceId,
    required String roomName,
    required int currentUserId,
  }) async {
    _setLoading(true);
    _currentRoomName = roomName;
    _currentAnnonceId = annonceId;

    try {
      await _loadChatToken();

      // Vérifier si _chatToken est bien défini avant d'aller plus loin
      if (_chatToken == null) {
        throw Exception("Chat token is null, unable to initialize chat.");
      }

      // D'abord, nettoyer l'ancienne connexion
      await disposeChatResources();

      // Connect to WebSocket
      _chatService.connectToChat(
        annonceId,
        roomName,
        _chatToken!,
      );

      // Remplacer l'ancien abonnement
      _messageSubscription?.cancel();
      _messageSubscription = _chatService.messageStream.listen((message) {
        _messages.add(message);
        notifyListeners();
      });

      // Load chat history
      await loadChatHistory(roomName, _chatToken!);
      await getUserInteractions(); //actualiser notification
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize chat: $e');
      debugPrint('Failed to initialize chat: $e');
    }
  }

  Future<void> disposeChatResources() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _chatService.disconnectChatWebSocket();
    _messages.clear();
  }

  // Load chat history
  Future<void> loadChatHistory(String roomName, String authToken) async {
    _setLoading(true);

    try {
      final messages = await _chatService.getChatHistory(roomName, authToken);
      _messages = messages;
      debugPrint('message in room: $_messages');
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load chat history: $e');
    }
  }

  // Send text message
  void sendTextMessage({
    required String message,
    required int senderId,
    required String senderName,
    String? senderImageUrl,
  }) {
    if (_currentRoomName == null) {
      _setError('No active chat room');
      return;
    }

    _chatService.sendTextMessage(
      message: message,
      roomName: _currentRoomName!,
      senderId: senderId,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
    );
  }

  // Send image
  Future<void> sendImage(File imageFile, int senderId) async {
    if (_currentRoomName == null) {
      _setError('No active chat room');
      return;
    }

    await _chatService.sendFile(
      file: imageFile,
      fileType: 'image',
      roomName: _currentRoomName!,
      senderId: senderId,
    );
  }

  // Start recording audio
  Future<void> startRecording() async {
    try {
      if (!_isRecorderInitialized) {
        await initializeRecorder();
      }

      final directory = await getTemporaryDirectory();
      _recordingPath =
          '${directory.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder.startRecorder(
        codec: Codec.aacADTS,
        toFile: _recordingPath, // file to send to Django
      );

      _isRecording = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to start recording: $e');
    }
  }

  // Stop recording and get the file
  Future<File?> stopRecording() async {
    debugPrint("dans stop record $_isRecording   $_recordingPath");
    try {
      //if (!_isRecording || _recordingPath == null) return null;
      if (_recordingPath == null) return null;

      await _audioRecorder.stopRecorder();
      _isRecording = false;
      notifyListeners();

      if (_recordingPath != null) {
        return File(_recordingPath!);
      }
      return null;
    } catch (e) {
      _setError('Failed to stop recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  // Send recorded audio
  Future<void> sendRecordedAudio(int senderId) async {
    if (_currentRoomName == null) {
      _setError('No active chat room');
      return;
    }

    final audioFile = await stopRecording();
    if (audioFile != null) {
      await _chatService.sendFile(
        file: audioFile,
        fileType: 'audio',
        roomName: _currentRoomName!,
        senderId: senderId,
      );
    } else {
      debugPrint("Audio file vide: $audioFile");
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();

    // Clear error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _errorMessage = null;
      notifyListeners();
    });
  }

  // Clean up resources
  @override
  void dispose() {
    _chatService.dispose();
    debugPrint("ChatProvider dispose() appelé");
    _chatService.disconnectChatWebSocket();
    if (_isRecorderInitialized) {
      _audioRecorder.closeRecorder();
    }
    super.dispose();
  }
}
