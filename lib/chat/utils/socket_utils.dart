import 'package:tadiago/utils/constant.dart';

class WebSocketConfig {
  static String getWebSocketUrl({
    required int annonceId,
    required String roomName,
  }) {
    final Uri baseUri = Uri.parse(myBaseUrl);

    // Remove any trailing slashes from the room name
    final cleanRoomName = roomName.replaceAll(RegExp(r'[/#]+$'), '');

    // Ensure correct scheme conversion
    String scheme = baseUri.scheme == "https" ? "wss" : "ws";

    // Build the WebSocket URL without a trailing slash
    return "$scheme://${baseUri.host}:${baseUri.port}/ws/messages/$annonceId/$cleanRoomName";
  }
}
