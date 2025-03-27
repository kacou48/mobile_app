import 'package:flutter/material.dart';
import 'package:tadiago/components/costum_app_bar.dart';

class MyOwnAds extends StatefulWidget {
  const MyOwnAds({super.key});

  @override
  State<MyOwnAds> createState() => _MyOwnAdsState();
}

class _MyOwnAdsState extends State<MyOwnAds> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Mes annonces",
      ),
      body: Container(),
    );
  }
}
