import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/models/user_models.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/chat/models/chats_models.dart';
import 'package:tadiago/chat/providres/chats_provider.dart';
import 'package:tadiago/chat/utils/audio_player.dart';
import 'package:tadiago/config/themes.dart';
import 'package:tadiago/utils/color.dart';

class MyChatRoom extends StatefulWidget {
  const MyChatRoom({super.key});

  @override
  State<MyChatRoom> createState() => _MyChatRoomState();
}

class _MyChatRoomState extends State<MyChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<MessageModel> _messages = [];

  final ImagePicker _imagePicker = ImagePicker();

  //audio variable
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showAudioPreview = false;
  String? _audioPreviewPath;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // ignore: unused_field
  Map<String, dynamic>? _interaction;
  // ignore: unused_field
  User? _user;
  //String? _accessToken;

  @override
  void dispose() {
    debugPrint("Dispose appelé: fermeture du WebSocket");
    // Nettoyer la connexion WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final chatProvider = context.read<ChatsProvider>();
        await chatProvider.disposeChatResources();
      }
    });

    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // @override
  // void deactivate() {
  //   final chatProvider = Provider.of<ChatsProvider>(context, listen: false);
  //   chatProvider.disposeChatResources();
  //   super.deactivate();
  // }

  @override
  void initState() {
    super.initState();

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

    // Assurer que WebSocket est bien initialisé après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatAndRecorder();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérez l'annonce passée en argument
    _interaction =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.user;
  }

  void _initializeChatAndRecorder() async {
    if (!mounted || _user == null) {
      return;
    }

    final chatProvider = Provider.of<ChatsProvider>(context, listen: false);

    // Étape 1 : Initialiser WebSocket en premier
    await chatProvider.initializeChat(
      annonceId: _interaction!['annonce_id'],
      roomName: _interaction!['room_name'],
      currentUserId: _user!.id,
    );

    // Étape 2 : Ajouter un léger délai puis initialiser l'enregistreur audio
    Future.delayed(Duration(milliseconds: 200), () {
      chatProvider.initializeRecorder();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        if (!mounted) return;
        final chatProvider = Provider.of<ChatsProvider>(context, listen: false);
        await chatProvider.sendImage(
          File(image.path),
          _user!.id, //current userId
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    final chatProvider = Provider.of<ChatsProvider>(context, listen: false);

    if (chatProvider.isRecording) {
      // Stop recording and show preview
      final audioFile = await chatProvider.stopRecording();
      if (audioFile != null) {
        setState(() {
          _showAudioPreview = true;
          _audioPreviewPath = audioFile.path;
        });
        // Load the audio file for preview
        await _audioPlayer.setSource(DeviceFileSource(audioFile.path));
      }
    } else {
      // Start recording
      await chatProvider.startRecording();
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPreviewPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.resume();
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _sendAudio() async {
    if (_audioPreviewPath != null) {
      final chatProvider = Provider.of<ChatsProvider>(context, listen: false);
      try {
        await chatProvider.sendRecordedAudio(_user!.id);

        //Supprimer le fichier audio après envoi
        final audioFile = File(_audioPreviewPath!);
        if (audioFile.existsSync()) {
          audioFile.deleteSync();
        }
        setState(() {
          _showAudioPreview = false;
          _audioPreviewPath = null;
          _isPlaying = false;
          _position = Duration.zero;
          _duration = Duration.zero;
        });
        _audioPlayer.stop();
      } catch (e) {
        debugPrint("Erreur lors de l'envoi de l'audio: $e");
      }
    }
  }

  void _deleteAudio() {
    setState(() {
      _showAudioPreview = false;
      _audioPreviewPath = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _audioPlayer.stop();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    debugPrint('message null ${_messageController.text.trim()}');
    if (message.isEmpty) return;

    final chatProvider = Provider.of<ChatsProvider>(context, listen: false);
    chatProvider.sendTextMessage(
      message: message,
      senderId: _user!.id,
      senderName: _user!.name,
      senderImageUrl: _user!.imageUrl,
    );
    debugPrint('message non null $message');

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      NetworkImage('${_interaction?['image_url']}'),
                  //NetworkImage('$myBaseUrl${_interaction?['image_url']}'),
                ),
                const SizedBox(width: 8),
                Text(
                  "${_interaction?['first_name']} ${_interaction?['last_name']}",
                  style: AppTextStyles.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 5),
            child: Material(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white,
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: "Joindre un fichier",
                      onPressed: _pickImage,
                      icon: Icon(Icons.attach_file_outlined),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5, // Empêche le champ de devenir trop grand
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        focusNode:
                            _focusNode, // Pour gérer le focus et éviter que le clavier ferme le champ
                        style: TextStyle(fontFamily: "Bold"),
                        decoration: InputDecoration(
                          hintText: "Votre message...",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade500, fontFamily: "Bold"),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        onTap: () =>
                            _scrollToBottom(), // Garde l'espace visible quand on tape
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _messageController,
                      builder: (context, value, child) {
                        return IconButton(
                          tooltip: "Envoyer",
                          onPressed: value.text.trim().isNotEmpty
                              ? _sendMessage
                              : null,
                          icon: Icon(Icons.send, color: Colors.green),
                        );
                      },
                    ),
                    Consumer<ChatsProvider>(
                      builder: (context, chatProvider, child) {
                        return AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: IconButton(
                            key: ValueKey(chatProvider.isRecording),
                            icon: Icon(
                              chatProvider.isRecording
                                  ? Icons.stop_circle
                                  : Icons.mic,
                              color:
                                  chatProvider.isRecording ? Colors.red : null,
                            ),
                            onPressed: _toggleRecording,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: Consumer<ChatsProvider>(
                  builder: (context, chatProvider, child) {
                    if (chatProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (chatProvider.errorMessage != null) {
                      return Center(
                          child: Text('Error: ${chatProvider.errorMessage}'));
                    }

                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());

                    _messages = chatProvider.messages;
                    //print("receiver: $_messages");

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                          right: 10,
                          left: 10,
                          top: 10),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isCurrentUser = message.senderId == _user!.id;

                        return _buildMessageBubble(message, isCurrentUser);
                      },
                    );
                  },
                ),
              ),

              // Audio preview
              if (_showAudioPreview)
                Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      _audioPreviews(),
                      SizedBox(
                        height: 60,
                      )
                    ],
                  ),
                )
            ],
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
                  value: _position.inSeconds.toDouble(),
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
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
                onPressed: _deleteAudio,
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

  Widget _buildMessageBubble(MessageModel message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? chatMecolor //Theme.of(context).colorScheme.primary.withOpacity(0.9)
              : chatYouColors, //Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content based on type
            if (message.messageType == 'text' && message.message != null)
              Text(
                message.message!,
                style: TextStyle(color: Colors.black87, fontFamily: "Bold"),
              )
            else if (message.messageType == 'image' && message.imageUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "${message.imageUrl}",
                      //"$myBaseUrl${message.imageUrl}",
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ],
              )
            else if (message.messageType == 'audio' && message.audioUrl != null)
              //MyAudioPlayer(audioUrl: '$myBaseUrl${message.audioUrl!}'),
              MyAudioPlayer(audioUrl: message.audioUrl!),

            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('yyyy, EEE HH:mm', 'fr_FR')
                    .format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
