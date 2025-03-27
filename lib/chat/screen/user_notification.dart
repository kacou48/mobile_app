import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/chat/providres/chats_provider.dart';
import 'package:tadiago/config/themes.dart';
//import 'package:tadiago/utils/constant.dart';

class UserNotification extends StatefulWidget {
  const UserNotification({super.key});

  @override
  State<UserNotification> createState() => _UserNotificationState();
}

class _UserNotificationState extends State<UserNotification> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Naviguer vers la page 'main_home_page'
            Navigator.pushNamed(context, '/main_home_page');
          },
        ),
      ),
      body: Consumer<ChatsProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isNotifLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Affichage du message d'erreur avec un bouton de rafraîchissement
          if (chatProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chatProvider.errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      chatProvider.getUserInteractions();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text("Réessayer"),
                  ),
                ],
              ),
            );
          }

          // Afficher un message si la liste est vide
          if (chatProvider.userInteractions.isEmpty) {
            return Center(
              child: Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: chatProvider.userInteractions.length,
            itemBuilder: (context, index) {
              final interaction = chatProvider.userInteractions[index];
              return _chatLitle(
                context: context,
                firstName: interaction['first_name'],
                lastName: interaction['last_name'],
                lastMessage: interaction['last_message'],
                lastMessageDate: interaction['last_message_date'],
                imageUrl: interaction['image_url'],
                unreadCount: interaction['unread_count'] ?? 0,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/my_chat_room',
                    arguments: interaction,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _chatLitle({
    required BuildContext context,
    required String firstName,
    required String imageUrl,
    required String lastName,
    required String? lastMessage,
    required String? lastMessageDate,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    bool hasUnreadMessages = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                imageUrl.isNotEmpty
                    ? imageUrl //"$myBaseUrl$imageUrl"
                    : "https://via.placeholder.com/60",
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 30, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Message content - using Expanded to prevent overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$firstName $lastName",
                    style: AppTextStyles.bodyText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage?.isNotEmpty == true
                        ? lastMessage!
                        : "Un fichier envoyé",
                    style: AppTextStyles.labelMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Nombre de messages non lus
            if (hasUnreadMessages)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Time stamp
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                lastMessageDate != null && lastMessageDate.isNotEmpty
                    ? DateFormat('yyyy, EEE HH:mm', 'fr_FR').format(
                        DateTime.tryParse(lastMessageDate) ?? DateTime.now())
                    : '',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
