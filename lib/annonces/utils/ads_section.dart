import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AdsSection extends StatelessWidget {
  const AdsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> adImages = [
      "https://via.placeholder.com/200x100",
      "https://via.placeholder.com/200x100",
      "https://via.placeholder.com/200x100"
    ];
    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 200,
          child: CarouselSlider.builder(
            itemCount: adImages.length,
            itemBuilder: (context, index, realIndex) {
              return Container(
                margin: EdgeInsets.only(right: 2, bottom: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Image.network(
                  adImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 200, // Hauteur du carousel
              viewportFraction: 0.95, // Largeur de chaque item
              autoPlay: true, // Lecture automatique (si nécessaire)
              autoPlayInterval: const Duration(seconds: 5),
              reverse: false,
              autoPlayAnimationDuration: const Duration(microseconds: 800),
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
              padEnds: true,
            ),
          ),
        ),
      ],
    );
  }
}
