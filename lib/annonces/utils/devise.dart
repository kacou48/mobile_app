import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

Future<String?> getDeviceId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // Android ID
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor; // IDFV
  }
  return null;
}

Future<Map<String, String>> getDeviceHeaders() async {
  final headers = {'Content-Type': 'application/json'};

  try {
    final deviceId = await getDeviceId();
    if (deviceId != null) {
      headers['X-Device-ID'] = deviceId;
      debugPrint('Getting device ID: $deviceId');
    }
  } catch (e) {
    debugPrint('Error getting device ID: $e');
  }

  return headers;
}
