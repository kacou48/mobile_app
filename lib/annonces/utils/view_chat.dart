import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class MyViewChat extends StatefulWidget {
  final List<Map<String, dynamic>> adsList;
  final Function(int year, int? annonceId) onTab;

  const MyViewChat({super.key, required this.adsList, required this.onTab});

  @override
  State<MyViewChat> createState() => _MyViewChatState();
}

class _MyViewChatState extends State<MyViewChat> {
  int selectedYear = DateTime.now().year;
  int? selectedAnnonceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTab(selectedYear, selectedAnnonceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdsProvider>(
      builder: (context, adsProvider, child) {
        if (adsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adsProvider.error != null) {
          return Center(child: Text(adsProvider.error!));
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(4, (index) {
                    int year = DateTime.now().year - index;
                    return DropdownMenuItem(
                        value: year, child: Text(year.toString()));
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                    widget.onTab(selectedYear, selectedAnnonceId);
                  },
                ),
                DropdownButton<int?>(
                  value: selectedAnnonceId,
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text("Toutes les annonces")),
                    ...widget.adsList.map((ad) {
                      String truncatedTitle = ad['title'].length > 20
                          ? '${ad['title'].substring(0, 20)}...'
                          : ad['title'];
                      return DropdownMenuItem(
                          value: ad['id'], child: Text(truncatedTitle));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedAnnonceId = value;
                    });
                    widget.onTab(selectedYear, selectedAnnonceId);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Total des vues en $selectedYear: ${adsProvider.totalViews}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                debugPrint("Graphique cliqué !");
              },
              child: SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: adsProvider.data.isNotEmpty
                        ? adsProvider.data.reduce((a, b) => a > b ? a : b) + 5
                        : 10,
                    barGroups: List.generate(
                      adsProvider.data.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: adsProvider.data[index].toDouble(),
                            color: Colors.blue,
                            width: 15,
                          ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 &&
                                index < adsProvider.labels.length) {
                              return Transform.rotate(
                                angle: -45 * (3.1415927 / 180),
                                child: Text(
                                  adsProvider.labels[index].substring(0, 3),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
