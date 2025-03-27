import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageModel {
  final int? id;
  final String? message;
  final String? imageUrl;
  final String? audioUrl;
  final int? senderId;
  final String senderName;
  final String? senderImageUrl;
  final DateTime timestamp;
  final bool isRead;
  final String messageType; // 'text', 'image', 'audio'

  MessageModel({
    this.id,
    this.message,
    this.imageUrl,
    this.audioUrl,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.timestamp,
    this.isRead = false,
    required this.messageType,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String? messageContent = json['my_message'] ?? json['message'];

    String? imageUrl = json['image'] ?? json['url'];

    String? audioUrl = json['audio'] ?? json['url'];

    // Handle the sender name which might come under different keys
    String senderName = json['sender'] ?? 'Unknown';

    // Handle the sender URL which might come under different keys
    String? senderUrl = json['sender_url'] ?? json['sender_image_url'];

    // Handle the message type
    String messageType = json['type'];

    // Handle sender_id which might be int or string
    int senderId;
    if (json['sender_id'] is String) {
      senderId = int.parse(json['sender_id']);
    } else {
      senderId = json['sender_id'] ?? 0;
    }

    // Handle id which might be int or string
    int? id;
    if (json['id'] != null) {
      id = json['id'] is String ? int.parse(json['id']) : json['id'];
    }

    // Handle the timestamp which might be missing
    DateTime timestamp;
    try {
      if (json['timestamp'] != null) {
        if (json['timestamp'] is String) {
          // Try parsing as ISO date first
          try {
            timestamp = DateTime.parse(json['timestamp']);
          } catch (e) {
            // If ISO parsing fails, try parsing as HH:mm
            try {
              final timeStr = json['timestamp'];
              final now = DateTime.now();
              final time = DateFormat('HH:mm').parse(timeStr);
              timestamp = DateTime(
                now.year,
                now.month,
                now.day,
                time.hour,
                time.minute,
              );
            } catch (e) {
              debugPrint('Error parsing time: $e');
              timestamp = DateTime.now();
            }
          }
        } else {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error handling timestamp: $e');
      timestamp = DateTime.now();
    }

    return MessageModel(
      id: id,
      message: messageContent,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      senderId: senderId,
      senderName: senderName,
      senderImageUrl: senderUrl,
      timestamp: timestamp,
      isRead: json['is_read'] ?? false,
      messageType: messageType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'my_message': message,
      'message': message,
      'image': imageUrl,
      'audio': audioUrl,
      'sender_id': senderId,
      'sender': senderName,
      'sender_url': senderImageUrl,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': messageType,
    };
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, message: $message, imageUrl: $imageUrl, audioUrl: $audioUrl, '
        'senderId: $senderId, senderName: $senderName, senderImageUrl: $senderImageUrl, '
        'timestamp: $timestamp, isRead: $isRead, messageType: $messageType)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          message == other.message &&
          imageUrl == other.imageUrl &&
          audioUrl == other.audioUrl &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          senderImageUrl == other.senderImageUrl &&
          timestamp == other.timestamp &&
          isRead == other.isRead &&
          messageType == other.messageType;

  @override
  int get hashCode =>
      id.hashCode ^
      message.hashCode ^
      imageUrl.hashCode ^
      audioUrl.hashCode ^
      senderId.hashCode ^
      senderName.hashCode ^
      senderImageUrl.hashCode ^
      timestamp.hashCode ^
      isRead.hashCode ^
      messageType.hashCode;
}

class ChatRoom {
  final String roomName;
  final int annonceId;
  final String? annonceName;
  final int? otherUserId;
  final String? otherUserName;
  final String? otherUserImageUrl;
  final DateTime lastMessageTime;
  final String? lastMessageText;

  ChatRoom({
    required this.roomName,
    required this.annonceId,
    this.annonceName,
    this.otherUserId,
    this.otherUserName,
    this.otherUserImageUrl,
    required this.lastMessageTime,
    this.lastMessageText,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomName: json['room_name'],
      annonceId: json['annonce_id'],
      annonceName: json['annonce_name'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      otherUserImageUrl: json['other_user_image_url'],
      lastMessageTime: json['last_message_date'] != null
          ? DateTime.parse(json['last_message_date'])
          : DateTime.now(),
      lastMessageText: json['last_message'],
    );
  }
}
