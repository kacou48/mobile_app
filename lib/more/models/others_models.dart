class Abus {
  final String annonceType;
  final String message;
  final int userId;
  final int annonceId;

  Abus({
    required this.annonceType,
    required this.message,
    required this.userId,
    required this.annonceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'annonce_type': annonceType,
      'message': message,
      'user': userId,
      'annonce_id': annonceId,
    };
  }
}

class Contact {
  final String nom;
  final String email;
  final String contenu;

  Contact({
    required this.nom,
    required this.email,
    required this.contenu,
  });

  Map<String, dynamic> toJson() {
    return {'nom': nom, 'contenu': contenu, 'email': email};
  }
}
