import 'package:flutter/material.dart';

class AdsFilterDialog extends StatefulWidget {
  final RangeValues initialPriceRange;
  final String? initialCategory;
  final List<Map<String, dynamic>> categories;
  final Function(RangeValues, String?) onApply;
  final VoidCallback onReset;

  const AdsFilterDialog({
    super.key,
    required this.initialPriceRange,
    required this.initialCategory,
    required this.categories,
    required this.onApply,
    required this.onReset,
  });

  static Future<void> show({
    required BuildContext context,
    required RangeValues initialPriceRange,
    required String? initialCategory,
    required List<Map<String, dynamic>> categories,
    required Function(RangeValues, String?) onApply,
    required VoidCallback onReset,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AdsFilterDialog(
        initialPriceRange: initialPriceRange,
        initialCategory: initialCategory,
        categories: categories,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<AdsFilterDialog> createState() => _AdsFilterDialogState();
}

class _AdsFilterDialogState extends State<AdsFilterDialog> {
  late RangeValues _tempPriceRange;
  String? _tempCategory;

  // Données des catégories

  @override
  void initState() {
    super.initState();
    _tempCategory = widget.initialCategory;
    _tempPriceRange = widget.initialPriceRange;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filtrer les annonces",
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Plage de Prix",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
            RangeSlider(
              values: _tempPriceRange,
              min: 0,
              max: 1000,
              divisions: 100,
              labels: RangeLabels(
                '\$${_tempPriceRange.start.round()}',
                '\$${_tempPriceRange.end.round()}',
              ),
              onChanged: (value) => {setState(() => _tempPriceRange = value)},
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Plage de Prix",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  )),
              value: _tempCategory,
              dropdownColor: Colors.black87,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    "Toute Categorie",
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),
                ...widget.categories.map((category) {
                  return DropdownMenuItem<String>(
                      child: Text(
                    category['name'],
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ));
                }).toList(),
              ],
              onChanged: (value) {
                setState(() => _tempCategory = value);
              },
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    label: const Text('Reset'),
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onApply(_tempPriceRange, _tempCategory);
                      Navigator.pop(context);
                    },
                    label: const Text('Apply'),
                    icon: const Icon(
                      Icons.check,
                    ),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
