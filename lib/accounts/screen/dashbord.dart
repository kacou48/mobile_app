import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/screen/profile_screen.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/annonces/utils/tab_items.dart';
import 'package:tadiago/annonces/utils/view_chat.dart';
//import 'package:tadiago/components/costum_app_bar.dart';
import 'package:tadiago/utils/color.dart';
//import 'package:tadiago/utils/constant.dart';

class Dashbord extends StatefulWidget {
  const Dashbord({super.key});

  @override
  State<Dashbord> createState() => _DashbordState();
}

class _DashbordState extends State<Dashbord> {
  List<Map<String, dynamic>>? _myAds;
  List<Map<String, dynamic>> _adsList = [];

  Future<void> _fetchVendorAds() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final ads = await adsProvider.getOnlyVendorAds();
    setState(() {
      _myAds = List<Map<String, dynamic>>.from(ads!);
      _adsList = _myAds!;
    });
  }

  Future<void> _getGraphicData(int year, int? annonceId) async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    await adsProvider.fetchViews(year: year, annonceId: annonceId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVendorAds();
      _getGraphicData(DateTime.now().year, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Tableau de bord",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Colors.black45,
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                        color: redColor,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10))),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: const [
                      TabItems(title: "Annonces", count: 1),
                      TabItems(title: "Profil", count: 2),
                      TabItems(title: "Dashbord", count: 3),
                    ],
                  ),
                ),
              )),
        ),
        body: TabBarView(children: [
          _myAdList(),
          ProfileScreen(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: MyViewChat(adsList: _adsList, onTab: _getGraphicData),
          ),
        ]),
      ),
    );
  }

  Widget _myAdList() {
    if (_myAds == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_myAds!.isEmpty) {
      return Center(child: Text("Aucune annonce trouvée."));
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _myAds!.length,
      itemBuilder: (context, index) {
        final ad = _myAds![index];

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/update_my_ads',
              arguments: ad,
            );
          },
          child: Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ad['first_image_url'] != null
                    ? Image.network(
                        //'$myBaseUrl${ad['first_image_url']}',
                        '${ad['first_image_url']}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/default_image.jpg', // Image par défaut
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/default_image.jpg', // Image par défaut
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
              ),
              title: Text(
                ad['title'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${ad['price']} Fcfa",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        "${ad['views_count']} vues",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ),
          ),
        );
      },
    );
  }
}
