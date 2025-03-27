import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tadiago/config/themes.dart';

class AdsCard extends StatefulWidget {
  final String vendorFullName;
  final String? vendorImage;
  final String title;
  final int price;
  final DateTime createdAt;
  final String location;
  final int imageCount;
  final String? imageUrl;
  final String subCategoryName;
  final int favorite;
  final VoidCallback onTap;
  final Function(int)
      onCarTap; // Modifier pour retourner le nouvel état de favorite

  const AdsCard({
    super.key,
    required this.vendorFullName,
    this.vendorImage,
    required this.title,
    required this.price,
    required this.location,
    required this.createdAt,
    required this.imageCount,
    this.imageUrl,
    required this.subCategoryName,
    required this.favorite,
    required this.onTap,
    required this.onCarTap,
  });

  @override
  State<AdsCard> createState() => _AdsCardState();
}

class _AdsCardState extends State<AdsCard> {
  late int _favorite; // État local de favorite

  @override
  void initState() {
    super.initState();
    _favorite = widget.favorite;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      color: const Color(0xFFF5F6F9),
      child: InkWell(
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 180,
            minWidth: 150,
            maxHeight: 350,
            minHeight: 300,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8.0)),
                    child: widget.imageUrl != null
                        ? Image.network(
                            widget.imageUrl!,
                            height: screenWidth * 0.25, // Adaptatif
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, object, stackTrace) =>
                                Container(
                              height: screenWidth * 0.25,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Icon(Icons.image_not_supported)),
                            ),
                          )
                        : Container(
                            height: screenWidth * 0.25,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.image)),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.vendorImage != null)
                              CircleAvatar(
                                backgroundImage:
                                    NetworkImage(widget.vendorImage!),
                                radius: 15,
                              ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.vendorFullName,
                                  style: AppTextStyles.labelLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(widget.createdAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontFamily: "Regular",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.title} - ${widget.location}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                              fontFamily: "Bold"),
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis, // Evite le dépassement
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.price} FCFA',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Bold"),
                            ),
                            InkWell(
                              onTap: () async {
                                final newFavorite =
                                    await widget.onCarTap(_favorite);
                                setState(() {
                                  _favorite = newFavorite;
                                });
                              },
                              child: Icon(
                                _favorite == 1
                                    ? Icons.favorite
                                    : Icons.favorite_border_outlined,
                                color: _favorite == 1 ? Colors.red : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  height: 20,
                  width: 30,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 1, 35, 52),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.imageCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Card(
  //     child: InkWell(
  //       onTap: widget.onTap,
  //       child: SizedBox(
  //         width: 180,
  //         height: 350,
  //         child: Stack(
  //           children: [
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 ClipRRect(
  //                   borderRadius:
  //                       const BorderRadius.vertical(top: Radius.circular(8.0)),
  //                   child: widget.imageUrl != null
  //                       ? Image.network(
  //                           widget.imageUrl!,
  //                           height: 90,
  //                           width: double.infinity,
  //                           fit: BoxFit.cover,
  //                           errorBuilder: (context, object, stackTrace) =>
  //                               Container(
  //                             height: 90,
  //                             color: Colors.grey[300],
  //                             child: const Center(
  //                                 child: Icon(Icons.image_not_supported)),
  //                           ),
  //                         )
  //                       : Container(
  //                           height: 90,
  //                           color: Colors.grey[300],
  //                           child: const Center(child: Icon(Icons.image)),
  //                         ),
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.all(8.0),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: [
  //                           if (widget.vendorImage != null)
  //                             CircleAvatar(
  //                               backgroundImage:
  //                                   NetworkImage(widget.vendorImage!),
  //                               radius: 15,
  //                             ),
  //                           const SizedBox(width: 4),
  //                           Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 widget.vendorFullName,
  //                                 style: AppTextStyles.labelLarge,
  //                                 // style: const TextStyle(
  //                                 //   fontWeight: FontWeight.bold,
  //                                 //   fontSize: 15,
  //                                 //   color: Colors.black54,
  //                                 // ),
  //                               ),
  //                               Text(
  //                                 DateFormat('dd/MM/yyyy')
  //                                     .format(widget.createdAt),
  //                                 style: const TextStyle(
  //                                   fontSize: 15,
  //                                   fontFamily: "Regular",
  //                                   color: Colors.grey,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         '${widget.title} - ${widget.location}',
  //                         style: const TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           fontFamily: "Bold",
  //                           fontSize: 14,
  //                           color: Colors.black87,
  //                         ),
  //                         maxLines: 2,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           Text(
  //                             '${widget.price} FCFA',
  //                             style: const TextStyle(
  //                                 fontSize: 15,
  //                                 color: Colors.grey,
  //                                 fontWeight: FontWeight.w600,
  //                                 fontFamily: "Bold"),
  //                           ),
  //                           InkWell(
  //                             onTap: () async {
  //                               // Appeler onCarTap et mettre à jour l'état local
  //                               final newFavorite =
  //                                   await widget.onCarTap(_favorite);
  //                               setState(() {
  //                                 _favorite = newFavorite;
  //                               });
  //                             },
  //                             child: Icon(
  //                               _favorite == 1
  //                                   ? Icons.favorite
  //                                   : Icons.favorite_border_outlined,
  //                               color: _favorite == 1 ? Colors.red : null,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             Positioned(
  //               top: 8,
  //               right: 8,
  //               child: Container(
  //                 height: 20,
  //                 width: 30,
  //                 decoration: BoxDecoration(
  //                   color: const Color.fromARGB(255, 1, 35, 52),
  //                   borderRadius: BorderRadius.circular(20),
  //                   border: null,
  //                 ),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       '${widget.imageCount}',
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w800,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
