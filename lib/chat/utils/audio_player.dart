import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MyAudioPlayer extends StatefulWidget {
  final String audioUrl;
  const MyAudioPlayer({super.key, required this.audioUrl});

  @override
  State<MyAudioPlayer> createState() => _MyAudioPlayerState();
}

class _MyAudioPlayerState extends State<MyAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() => _duration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() => _position = newPosition);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  Future<void> _toggleAudioPlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
