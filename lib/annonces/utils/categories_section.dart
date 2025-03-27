import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/models/ads_models.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';

class CategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(String) onSubcategorySelected;
  //final List<Category> categories;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.onSubcategorySelected,
  });

  IconData getIconData(String iconName) {
    Map<String, IconData> iconMap = {
      'directions_car': Icons.directions_car,
      'apartment': Icons.apartment,
      'work': Icons.work,
      'shopping_bag': Icons.shopping_bag,
      'home': Icons.home,
      'sports_esports': Icons.sports_esports,
      'devices': Icons.devices,
      'category': Icons.category,
      'build': Icons.build,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[iconName] ?? Icons.error;
  }

  Color hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", ""); // Supprimez le "#"
    return Color(int.parse("0xFF$hexColor"));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          height: 90,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 9),
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final adsProvider = Provider.of<AdsProvider>(
                                  context,
                                  listen: false);
                              final subcategories = await adsProvider
                                  .fetchAdSubcategories(category['id']);

                              if (context.mounted) {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return SubcategoryBottomSheet(
                                      subcategories: subcategories,
                                      onSubcategorySelected:
                                          onSubcategorySelected,
                                    );
                                  },
                                );
                              } else {
                                debugPrint(
                                    "Context is no longer mounted, cannot show BottomSheet.");
                              }
                            } catch (e) {
                              if (context.mounted) {
                                //Important to check context.mounted also for snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(
                            getIconData(category['icon']),
                            size: 35,
                            color: hexToColor(category['color']),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: "Bold",
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SubcategoryBottomSheet extends StatelessWidget {
  final List<SubCategory> subcategories;
  final Function(String) onSubcategorySelected; // Add callback function

  const SubcategoryBottomSheet({
    super.key,
    required this.subcategories,
    required this.onSubcategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final subcategory = subcategories[index];
              return Card(
                elevation: 2, // Add a subtle shadow
                margin: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16), // Add margin
                shape: RoundedRectangleBorder(
                  // Rounded corners for the Card
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                      Icons.category), // Add an icon (customize as needed)
                  title: Text(
                    subcategory.name,
                    style: const TextStyle(
                      // Style the text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    onSubcategorySelected(subcategory.name);
                    Navigator.pop(context);
                  },
                  trailing: const Icon(
                      Icons.arrow_forward_ios), // Add a trailing icon
                ),
              );
            },
          ),
        );
      },
    );
  }
}
