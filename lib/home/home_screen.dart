import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/models/ads_models.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/annonces/utils/categories_section.dart';
import 'package:tadiago/components/app_drawer.dart';
import 'package:tadiago/components/home_app_bar.dart';
import 'package:tadiago/components/home_search_bar.dart';
import 'package:tadiago/components/ads_list.dart';

// home_screen.dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSubcategory;

  //List<Map<String, dynamic>> categories = categories;
  List<Map<String, dynamic>> _categoriesList = [];

  void _onSubcategorySelected(String subcategoryName) {
    setState(() {
      _selectedSubcategory = subcategoryName;
      _updateAdsList();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedSubcategory = null;
      _updateAdsList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _updateAdsList();
    });
  }

  Future<void> _getCategories() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    List<Category> categories;
    if (adsProvider.categories.isEmpty) {
      await adsProvider.fetchCategories();
      categories = adsProvider.categories;
    } else {
      categories = adsProvider.categories;
    }
    _categoriesList = categories
        .map((cat) => {
              "id": cat.id,
              "name": cat.name,
              "color": cat.color,
              "icon": cat.icon
            })
        .toList();

    setState(() {});
  }

  void _updateAdsList() {
    context.read<AdsProvider>().resetPagination();
    String? subcategoryToUse = _selectedSubcategory;

    if (_searchQuery.isNotEmpty) {
      subcategoryToUse = null;
    }

    context.read<AdsProvider>().fetchAds(
          searchQuery: _searchQuery,
          subcategory: subcategoryToUse,
        );
  }

  void _onFilterTap() {
    _selectedSubcategory = null;
    _updateAdsList();
  }

  @override
  void initState() {
    super.initState();
    _getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, //kPrimaryLightColor,
      appBar: const HomeAppBar(),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            HomeSearchBar(
              searchQuery: _searchQuery,
              isSearching: _searchQuery.isNotEmpty,
              onFilterTap: _onFilterTap,
              onSearchChanged: _onSearchChanged,
              onSearchCleared: _clearSearch,
              searchController: _searchController,
            ),
            const SizedBox(height: 7),
            CategoriesSection(
              categories:
                  _categoriesList, //categories, // Pass the categories list here
              onSubcategorySelected: _onSubcategorySelected,
            ),
            Expanded(
              child: AdsList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
