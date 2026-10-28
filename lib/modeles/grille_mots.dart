/// Une grille du jeu Words : 16 lettres (4 × 4), un mot caché dedans et
/// sa traduction française (affichée une fois le mot trouvé).
class GrilleMots {
  const GrilleMots({
    required this.lettres,
    required this.motCible,
    required this.traduction,
  });

  /// 16 lettres, index = ligne * 4 + colonne.
  final List<String> lettres;
  final String motCible;
  final String traduction;

  factory GrilleMots.fromJson(Map<String, dynamic> json) {
    return GrilleMots(
      lettres: List<String>.from(json['lettres'] as List),
      motCible: json['motCible'] as String,
      traduction: json['traduction'] as String,
    );
  }

  Map<String, dynamic> versJson() => {
    'lettres': lettres,
    'motCible': motCible,
    'traduction': traduction,
  };
}
