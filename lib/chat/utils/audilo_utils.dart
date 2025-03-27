import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecord {
  // Audio recording
  static final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  static bool _isRecorderInitialized = false;
  static String? _recordingPath;
  static bool _isRecording = false;
  static bool get isRecording => _isRecording;

  Future<void> initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _audioRecorder.openRecorder();
    _isRecorderInitialized = true;
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
    } catch (e) {
      debugPrint('Failed to start recording: $e');
    }
  }

  // Stop recording and get the file
  Future<File?> stopRecording() async {
    debugPrint("dans stop record $_isRecording   $_recordingPath");
    try {
      if (_recordingPath == null) return null;

      await _audioRecorder.stopRecorder();
      _isRecording = false;

      if (_recordingPath != null) {
        return File(_recordingPath!);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Release resources
  static Future<void> dispose() async {
    if (_isRecorderInitialized) {
      await _audioRecorder.closeRecorder();
      _isRecorderInitialized = false;
    }
  }
}

// class AudioUtils {
//   static FlutterSoundRecorder? _recorder;
//   static FlutterSoundPlayer? _player;
//   static bool _isRecorderInitialized = false;
//   static bool _isPlayerInitialized = false;
//   static String? _recordingPath;

//   // Initialize recorder
//   static Future<void> initRecorder() async {
//     _recorder = FlutterSoundRecorder();

//     final status = await Permission.microphone.request();
//     if (status != PermissionStatus.granted) {
//       throw RecordingPermissionException('Microphone permission not granted');
//     }

//     await _recorder!.openRecorder();
//     _isRecorderInitialized = true;
//   }

//   // Initialize player
//   static Future<void> initPlayer() async {
//     _player = FlutterSoundPlayer();
//     await _player!.openPlayer();
//     _isPlayerInitialized = true;
//   }

//   // Start recording
//   static Future<void> startRecording() async {
//     if (!_isRecorderInitialized) {
//       await initRecorder();
//     }

//     final directory = await getTemporaryDirectory();
//     _recordingPath =
//         '${directory.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.aac';

//     await _recorder!.startRecorder(
//       toFile: _recordingPath,
//       codec: Codec.aacADTS,
//     );
//   }

//   // Stop recording and return file
//   static Future<File?> stopRecording() async {
//     if (!_isRecorderInitialized || !_recorder!.isRecording) {
//       return null;
//     }

//     await _recorder!.stopRecorder();

//     if (_recordingPath != null) {
//       return File(_recordingPath!);
//     }
//     return null;
//   }

//   // Play audio from URL
//   static Future<void> playAudio(String url) async {
//     if (!_isPlayerInitialized) {
//       await initPlayer();
//     }

//     await _player!.startPlayer(
//       fromURI: url,
//       codec: Codec.aacADTS,
//     );
//   }

//   // Stop playing
//   static Future<void> stopPlaying() async {
//     if (!_isPlayerInitialized || !_player!.isPlaying) {
//       return;
//     }

//     await _player!.stopPlayer();
//   }

//   // Release resources
//   static Future<void> dispose() async {
//     if (_isRecorderInitialized) {
//       await _recorder!.closeRecorder();
//       _recorder = null;
//       _isRecorderInitialized = false;
//     }

//     if (_isPlayerInitialized) {
//       await _player!.closePlayer();
//       _player = null;
//       _isPlayerInitialized = false;
//     }
//   }
// }
