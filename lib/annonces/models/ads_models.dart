class Ad {
  final int id;
  final String title;
  final int price;
  final String localisation;
  final DateTime createdAt;
  final String? imageUrl;
  final int imageCount;
  final int favorite;
  final Category category;
  final SubCategory subCategory;
  final Vendor vendor;

  Ad({
    required this.id,
    required this.title,
    required this.price,
    required this.localisation,
    required this.createdAt,
    this.imageUrl,
    required this.imageCount,
    required this.favorite,
    required this.category,
    required this.subCategory,
    required this.vendor,
  });

  // Méthode copyWith
  Ad copyWith({
    int? id,
    String? title,
    int? price,
    String? localisation,
    DateTime? createdAt,
    String? imageUrl,
    int? imageCount,
    int? favorite,
    Category? category,
    SubCategory? subCategory,
    Vendor? vendor,
  }) {
    return Ad(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      localisation: localisation ?? this.localisation,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      imageCount: imageCount ?? this.imageCount,
      favorite: favorite ?? this.favorite,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      vendor: vendor ?? this.vendor,
    );
  }

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'],
      title: json['title'],
      price: json['price'],
      localisation: json['localisation'],
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['first_image_url']?.toString(),
      imageCount: json['images_count'],
      favorite: json['favorite_count'],
      category: Category.fromJson(json['category']),
      subCategory: SubCategory.fromJson(json['sub_category']),
      vendor: Vendor.fromJson(json['vendor']),
    );
  }
}

class Category {
  final int id;
  final String name;
  final String icon;
  final String color;

  Category(
      {required this.id,
      required this.name,
      required this.icon,
      required this.color});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
    );
  }
}

class SubCategory {
  final int id;
  final String name;

  SubCategory({
    required this.id,
    required this.name,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Vendor {
  final int id;
  final String name;
  final String firstname;
  final String imageUrl;
  final String getConnectionDuration;
  final String description;
  final DateTime birthDate;

  Vendor({
    required this.id,
    required this.name,
    required this.firstname,
    required this.imageUrl,
    required this.description,
    required this.birthDate,
    required this.getConnectionDuration,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['user']['id'],
      name: json['user']['name'],
      firstname: json['user']['firstname'],
      imageUrl: json['user']['image_url'],
      getConnectionDuration: json['user']['get_connection_duration'],
      birthDate: DateTime.parse(json['user']['birth_date']),
      description: json['description'] ?? "Pas de description",
    );
  }
}

class AdImage {
  final String imageUrl;

  AdImage({required this.imageUrl});

  factory AdImage.fromJson(Map<String, dynamic> json) {
    return AdImage(
        imageUrl: json['image_url'] as String); // Adaptez la clé si nécessaire
  }
}

class Pagination {
  final int count;
  final int page;
  final int numPages;
  final int limit;
  final String? next;
  final String? previous;
  final List<Ad> results;

  Pagination({
    required this.count,
    required this.page,
    required this.numPages,
    required this.limit,
    this.next,
    this.previous,
    required this.results,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      numPages: json['num_pages'] ?? 1,
      limit: json['limit'],
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: List<Ad>.from(json['results'].map((ad) => Ad.fromJson(ad))),
    );
  }
}

class AdDetails extends Ad {
  final String contenu;
  final String contenuText;
  final String typeDeTransaction;
  final List<AdImage> images; // Utilisez la classe AdImage existante
  final String? adsAudio;
  final int viewsCount;

  AdDetails({
    required super.id,
    required super.title,
    required super.price,
    required super.localisation,
    required super.createdAt,
    required super.imageUrl,
    required super.imageCount,
    required super.favorite,
    required super.category,
    required super.subCategory,
    required super.vendor,
    required this.contenu,
    required this.contenuText,
    required this.typeDeTransaction,
    required this.images,
    this.adsAudio,
    required this.viewsCount,
  });

  factory AdDetails.fromJson(Map<String, dynamic> json) {
    return AdDetails(
      id: json['id'],
      title: json['title'] ?? "Titre inconnu",
      price: json['price'] ?? 0, // Si price est null, mets 0
      localisation: json['localisation'] ?? "Localisation inconnue",
      createdAt: DateTime.tryParse(json['created_at'] ?? "") ??
          DateTime.now(), // Évite les erreurs de parsing
      imageUrl: (json['images'] != null && json['images'].isNotEmpty)
          ? json['images'][0]['image_url']
          : "", // Vérifie si images existe
      imageCount: (json['images'] != null) ? json['images'].length : 0,
      favorite: 0,
      category:
          Category.fromJson(json['category']), // Corrige le mauvais mapping
      subCategory: SubCategory.fromJson(json['sub_category']),
      vendor: Vendor.fromJson(json['vendor']),
      contenu: json['contenu'] ?? "",
      contenuText: json['contenu_text'] ?? "",
      typeDeTransaction: json['type_de_transaction'] ?? "Non spécifié",
      images: (json['images'] != null)
          ? List<AdImage>.from(
              json['images'].map((image) => AdImage.fromJson(image)))
          : [], // Vérifie si images existe avant de mapper
      adsAudio: json['audio'] as String?, // Assure que c'est nullable
      viewsCount: json['views_count'] ?? 0, // Évite l'erreur si null
    );
  }
}
