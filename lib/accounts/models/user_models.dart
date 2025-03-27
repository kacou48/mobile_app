class User {
  final int id;
  final String email;
  final String name;
  final String firstname;
  final String? telephone;
  final String? civility;
  final String? status;
  final String? city;
  final String? imageUrl;
  final bool isActive;
  final int? unreadMessagesCount;
  final String? connectionDuration;
  final Vendor? vendor;

  // il faut faire une copie pour la mise à jour
  User copyWith({
    int? id,
    String? email,
    String? name,
    String? firstname,
    String? telephone,
    String? civility,
    String? status,
    String? city,
    String? imageUrl,
    bool? isActive, // Added
    //int? unreadMessagesCount, // Added
    //String? connectionDuration, // Added
    Vendor? vendor,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      firstname: firstname ?? this.firstname,
      telephone: telephone ?? this.telephone,
      civility: civility ?? this.civility,
      status: status ?? this.status,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      //unreadMessagesCount: unreadMessagesCount?? this.unreadMessagesCount,
      //connectionDuration: connectionDuration?? this.connectionDuration,
      vendor: vendor ?? this.vendor,
    );
  }

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.firstname,
    this.telephone,
    this.civility,
    this.status,
    this.city,
    this.imageUrl,
    required this.isActive,
    this.unreadMessagesCount,
    this.connectionDuration,
    this.vendor,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      firstname: json['firstname'],
      telephone: json['telephone'],
      civility: json['civility'],
      status: json['status'],
      city: json['city'],
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'],
      unreadMessagesCount: json['unread_messages_count'],
      connectionDuration: json['connection_duration'],
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'firstname': firstname,
      'telephone': telephone,
      'civility': civility,
      'status': status,
      'city': city,
      'image_url': imageUrl,
      'is_active': isActive,
      'unread_messages_count': unreadMessagesCount,
      'connection_duration': connectionDuration,
      'vendor': vendor?.toJson(),
    };
  }
}

class Vendor {
  final String? description;
  final String? lieu;

  Vendor copyWith({String? description, String? lieu}) {
    return Vendor(
      description: description ?? this.description,
      lieu: lieu ?? this.lieu,
    );
  }

  Vendor({
    this.description,
    this.lieu,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      description: json['description'],
      lieu: json['lieu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'lieu': lieu,
    };
  }
}
