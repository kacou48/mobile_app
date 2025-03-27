//import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
//import 'package:cached_network_image/cached_network_image.dart';
//import 'package:path_provider/path_provider.dart';

//import 'package:provider/provider.dart';
//import 'package:record/record.dart';
//import 'package:just_audio/just_audio.dart';
//import 'package:path_provider/path_provider.dart';
//import 'package:path/path.dart' as p;
import 'package:tadiago/chat/providres/chats_provider.dart';
import 'package:tadiago/chat/utils/audio_player.dart';

//import 'package:flutter_sound/flutter_sound.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:tadiago/components/costum_app_bar.dart';
//import 'package:tadiago/utils/constant.dart';

class AdsAttachement extends StatefulWidget {
  const AdsAttachement({super.key});

  @override
  State<AdsAttachement> createState() => _AdsAttachementState();
}

class _AdsAttachementState extends State<AdsAttachement>
    with SingleTickerProviderStateMixin {
  //late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _uploadedImages = [];
  Map<String, dynamic>? _uploadedAudio;
  bool _isUploading = false;
  bool _isRecorderInitialized = false;

  //audio variable
  final AudioPlayer _audioPlayer = AudioPlayer();
  late File _audioFile = File('');
  // ignore: unused_field
  bool _showAudioPreview = false;
  String? _audioPreviewPath;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  //Timer? _recordingTimer;

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

    if (!_isRecorderInitialized) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          final chatProvider =
              Provider.of<ChatsProvider>(context, listen: false);
          chatProvider.initializeRecorder();
          _isRecorderInitialized = true;
        }
      });
    }
  }

  Future<void> _toggleRecording() async {
    final chatProvider = Provider.of<ChatsProvider>(context, listen: false);

    try {
      if (chatProvider.isRecording) {
        // Stop recording and show preview
        final audioFile = await chatProvider.stopRecording();
        //print("audio enregistré: $audioFile    isVisible: $_showAudioPreview");
        if (audioFile != null) {
          setState(() {
            _showAudioPreview = true;
            _audioPreviewPath = audioFile.path;
            _audioFile = audioFile;
          });
          // Load the audio file for preview
          //print("load the audio isVisible: $_showAudioPreview");
          await _audioPlayer.setSource(DeviceFileSource(_audioPreviewPath!));
          _duration = await _audioPlayer.getDuration() ?? Duration.zero;

          if (mounted) {
            Navigator.pop(context);
          } // Ferme le ModalBottomSheet
        }
      } else {
        // Start recording
        //print("start recording isVisible: $_showAudioPreview");
        await chatProvider.startRecording();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
      );
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPreviewPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.stop(); // Stop pour bien réinitialiser
        await _audioPlayer.setSource(DeviceFileSource(_audioPreviewPath!));
        // Réinitialiser la position avant de jouer
        await _audioPlayer.seek(Duration.zero);
        setState(() {
          _position = Duration.zero; // Réinitialiser la position
          _isPlaying = true;
        });
        await _audioPlayer.resume();
      }
    } catch (e) {
      print("Erreur lors de la lecture audio : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la lecture audio : $e")),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _deletePreviewsAudio() {
    setState(() {
      _showAudioPreview = false;
      _audioPreviewPath = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _audioPlayer.stop();
    _audioPlayer.release();
  }

  //on dois corriger ca il faut ca marche dabord dans backend
  Future<void> _deleteFile(int fileId, String typeFile) async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    await adsProvider.deleteFile(fileId: fileId, typeFile: typeFile);
    setState(() {
      if (typeFile == "image") {
        _uploadedImages.removeWhere((file) => file['file_id'] == fileId);
      } else if (typeFile == "audio") {
        _uploadedAudio = null;
      }
    });
  }

  void _sendAudio() async {
    if (!mounted) return;
    setState(() => _isUploading = true);

    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    int? adsId = adsProvider.getTemporaryAdId();

    if (adsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : Aucun ID d'annonce trouvé !")),
      );
      setState(() => _isUploading = false);
      return;
    }

    final result = await adsProvider.saveAdsImageOrAudio(
      file: _audioFile,
      adsId: adsId,
      typeFile: "audio",
    );

    if (!mounted) return;

    if (result['success'] && result['file_url'] != null) {
      setState(() => _uploadedAudio = {
            'file_url': result['file_url'],
            'file_id': result['file_id'],
          });
      debugPrint("Fichier audio uploadé avec succès : ${result['file_url']}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Erreur lors de l'upload audio : ${result['message'] ?? 'Inconnue'}")),
      );
    }

    setState(() => _isUploading = false);

    setState(() {
      _showAudioPreview = false;
      _audioPreviewPath = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _audioPlayer.stop();

    // Supprimer le fichier audio après envoi
    if (_audioPreviewPath != null) {
      final audioFile = File(_audioPreviewPath!);
      if (audioFile.existsSync()) {
        audioFile.deleteSync();
      }
    }
  }

  Future<void> _pickAndUploadFile(bool isImage, {bool isEdit = false}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    File file = File(pickedFile.path);

    if (!mounted) return;

    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    int? adsId = adsProvider.getTemporaryAdId();

    if (adsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : Aucun ID d'annonce trouvé !")),
      );
      setState(() => _isUploading = false);
      return;
    }

    // Détermine le type de fichier en fonction de isImage et isEdit
    String typeFile;
    if (isImage) {
      typeFile = isEdit ? "edite_image" : "image";
    } else {
      typeFile = "audio";
    }

    final result = await adsProvider.saveAdsImageOrAudio(
        file: file, adsId: adsId, typeFile: typeFile);

    if (result['success'] && result['file_url'] != null) {
      setState(() {
        if (isImage) {
          // _uploadedImages.add({
          //   'file_url': result['file_url'],
          //   'file_id': result['file_id'],
          // });
          final fileId = result['file_id'];
          if (isEdit && fileId != null) {
            // Remplacer l'image existante dans la liste
            final index =
                _uploadedImages.indexWhere((item) => item['file_id'] == fileId);
            print("index result: $index");
            if (index != -1) {
              _uploadedImages[index]['file_url'] = result['file_url'];
              _uploadedImages[index]['file_id'] = result['file_id'];
            }
          } else {
            // Ajouter une nouvelle image à la liste
            _uploadedImages.add({
              'file_url': result['file_url'],
              'file_id': result['file_id'],
            });
          }
          _updateAdsList();
        } else {
          _uploadedAudio = {
            'file_url': result['file_url'],
            'file_id': result['file_id'],
          };
        }
      });
    }

    setState(() => _isUploading = false);
  }

  void _updateAdsList() {
    context.read<AdsProvider>().resetPagination();

    context.read<AdsProvider>().fetchAds(
          searchQuery: null,
          subcategory: null,
        );
  }

  void _showModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.image, size: 30),
                            label: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Ajouter une Image',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: _isUploading
                                ? null
                                : () {
                                    _pickAndUploadFile(true);
                                    Navigator.pop(context);
                                  }),
                      ),
                      Consumer<ChatsProvider>(
                        builder: (context, chatProvider, child) {
                          return FloatingActionButton(
                            onPressed: _toggleRecording,
                            backgroundColor: chatProvider.isRecording
                                ? Colors.red
                                : Colors.blue,
                            child: Icon(
                              chatProvider.isRecording ? Icons.stop : Icons.mic,
                              size: 30,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      Text(
                        "Enregistrement audio",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageTab() {
    return ListView.builder(
      itemCount: _uploadedImages.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4, // Ombre portée
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '${_uploadedImages[index]['file_url']}',
                //'$myBaseUrl${_uploadedImages[index]['file_url']}',
                //_uploadedImages[index]['file_url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              "Image ${index + 1}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                index == 0 ? Icons.edit : Icons.delete,
                color: index == 0 ? Colors.blue : Colors.red,
                size: 24,
              ),
              onPressed: () {
                if (index == 0) {
                  //bouton pour editer l'image existante
                  _pickAndUploadFile(true, isEdit: true);
                } else {
                  // Fonction pour l'icône de suppression
                  _deleteFile(_uploadedImages[index]['file_id'], "image");
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: CustomAppBar(
        title: "Ajout de fichiers",
        onBackPressed: () => Navigator.pushNamed(
            context, '/main_home_page'), //Navigator.pop(context),
      ),
      body: Column(
        children: [
          if (_showAudioPreview) _audioPreviews(),
          if (_uploadedAudio != null && _uploadedAudio!['file_url'] != null)
            //MyAudioPlayer(audioUrl: '$myBaseUrl${_uploadedAudio!['file_url']}'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: MyAudioPlayer(
                        audioUrl: '${_uploadedAudio!['file_url']}'),
                    //audioUrl: '$myBaseUrl${_uploadedAudio!['file_url']}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteFile(_uploadedAudio!['file_id'], "audio");
                    },
                  ),
                ],
              ),
            ),
          Expanded(child: _buildImageTab()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showModalBottomSheet,
        child: const Icon(Icons.add),
      ),
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
                  //value: _position.inSeconds.toDouble(),
                  value: _position.inSeconds.toDouble().clamp(
                      0.0,
                      _duration.inSeconds > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0),
                  min: 0,
                  //max: _duration.inSeconds.toDouble(),
                  max: _duration.inSeconds > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
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
                onPressed: _deletePreviewsAudio,
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
