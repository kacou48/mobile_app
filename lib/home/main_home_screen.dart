import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/screen/dashbord.dart';
import 'package:tadiago/annonces/screen/save_ads.dart';
import 'package:tadiago/chat/providres/chats_provider.dart';
import 'package:tadiago/chat/screen/user_notification.dart';
import 'package:tadiago/home/home_screen.dart';
import 'dart:async';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int selectedIndex = 0;
  final List<Widget> pages = [
    const HomeScreen(),
    const UserNotification(),
    const Dashbord(),
    const SaveAds(),
  ];

  @override
  void initState() {
    super.initState();

    // Exécuter après le premier build pour éviter l'erreur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLoadNotificationsWithRetry();
    });
  }

  Future<void> _initLoadNotificationsWithRetry() async {
    if (!mounted) return;

    const maxRetries = 3;
    const retryInterval = Duration(seconds: 2);
    int attempt = 0;
    bool success = false;

    while (attempt < maxRetries && !success && mounted) {
      attempt++;
      debugPrint(
          "Tentative de chargement des notifications ($attempt/$maxRetries)");

      try {
        if (!mounted) return;
        final chatsProvider =
            Provider.of<ChatsProvider>(context, listen: false);

        // Connexion WebSocket au chargement de la page
        chatsProvider.connectToNotify();

        // Charger les interactions initiales
        await chatsProvider.getUserInteractions();
        success = true;
        debugPrint("Chargement des notifications réussi");
      } catch (e) {
        debugPrint(
            'Erreur lors du chargement des notifications (tentative $attempt): $e');

        // Si ce n'est pas la dernière tentative, attendre avant de réessayer
        if (attempt < maxRetries) {
          await Future.delayed(retryInterval);
        }
      }
    }

    if (!success && mounted) {
      debugPrint(
          "Échec du chargement des notifications après $maxRetries tentatives");
      // Vous pourriez ici afficher un message à l'utilisateur ou prendre une autre action
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<ChatsProvider>().unreadMessagesCount;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.black38,
        selectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        elevation: 4,
        backgroundColor: Colors.white70,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_max_outlined),
            label: "Accueil",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_active_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: "Notification",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: "Compte",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.publish_outlined),
            label: "Publier",
          ),
        ],
      ),
      body: pages[selectedIndex],
    );
  }
}
