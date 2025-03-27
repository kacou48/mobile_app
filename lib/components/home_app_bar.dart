import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/utils/color.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarState extends State<HomeAppBar> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdsProvider>(context, listen: false).getFavoriteCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adsProvider = Provider.of<AdsProvider>(context);
    debugPrint('favorite: ${adsProvider.favoriteCount}');

    return AppBar(
      backgroundColor: Colors.grey.shade50,
      surfaceTintColor: Colors.transparent,
      elevation: 5,
      shadowColor: Colors.black26,
      title: const Text(
        "Tadiago",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/mes_preferences');
              },
              icon: const Icon(
                Icons.favorite,
                color: Colors.black87,
              ),
            ),
            if (adsProvider.favoriteCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: redColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minHeight: 16,
                    minWidth: 16,
                  ),
                  child: Text(
                    '${adsProvider.favoriteCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
