import '../../core/network/json_reader.dart';

class CampusModel {
  final String id;
  final String name;
  final String? city;
  final String? institution;

  const CampusModel({
    required this.id,
    required this.name,
    this.city,
    this.institution,
  });

  factory CampusModel.fromJson(Map<String, dynamic> json) => CampusModel(
    id: json.stringOr('id', ''),
    name: json.stringOr('name', ''),
    city: json.optionalString('city'),
    institution: json.optionalString('institution'),
  );
}

/// Profil de la cantine, tel que renvoyé par `GET /vendors/me`.
class VendorModel {
  final String id;
  final String userId;
  final String canteenName;
  final String? logoUrl;
  final String? bannerUrl;
  final String? description;

  /// Solde retirable, en FCFA.
  final double balanceFcfa;

  /// Créance ouverte : kabakaba a avancé un remboursement à un étudiant.
  final double debtFcfa;

  /// Compte actif côté plateforme. `false` = suspendu par un administrateur.
  final bool isActive;

  /// Cantine ouverte aux commandes, basculable par le vendeur.
  final bool isOpen;

  /// Calculé par le serveur (`debtFcfa > 0`).
  ///
  /// C'est cette valeur qui décide de l'accès au retrait, jamais un
  /// recalcul local : la règle appartient au backend et peut évoluer.
  final bool withdrawalBlocked;

  final List<CampusModel> campuses;
  final String? phone;
  final DateTime? suspendedAt;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorModel({
    required this.id,
    required this.userId,
    required this.canteenName,
    this.logoUrl,
    this.bannerUrl,
    this.description,
    required this.balanceFcfa,
    required this.debtFcfa,
    required this.isActive,
    required this.isOpen,
    required this.withdrawalBlocked,
    this.campuses = const [],
    this.phone,
    this.suspendedAt,
    this.suspensionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  String get campusName => campuses.isEmpty ? '' : campuses.first.name;

  /// Initiales de la cantine, pour l'avatar par défaut.
  String get initials {
    final words = canteenName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Le vendeur peut-il demander un retrait ?
  bool get canWithdraw => isActive && !withdrawalBlocked && balanceFcfa > 0;

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final campuses = json
        .nestedList('campuses')
        .map(CampusModel.fromJson)
        .toList(growable: false);

    return VendorModel(
      id: json.requireString('id'),
      userId: json.stringOr('userId', ''),
      canteenName: json.stringOr('canteenName', 'Ma cantine'),
      logoUrl: json.optionalString('logoUrl'),
      bannerUrl: json.optionalString('bannerUrl'),
      description: json.optionalString('description'),
      balanceFcfa: json.decimalOr('balanceFcfa', 0),
      debtFcfa: json.decimalOr('debtFcfa', 0),
      isActive: json.boolOr('isActive', true),
      isOpen: json.boolOr('isOpen', false),
      // Repli sur la règle serveur connue si le champ manque, plutôt que
      // d'autoriser un retrait par défaut.
      withdrawalBlocked: json.boolOr(
        'withdrawalBlocked',
        json.decimalOr('debtFcfa', 0) > 0,
      ),
      campuses: campuses,
      phone: json.optionalString('phone'),
      suspendedAt: json.optionalDateTime('suspendedAt'),
      suspensionReason: json.optionalString('suspensionReason'),
      createdAt: json.requireDateTime('createdAt'),
      updatedAt: json.requireDateTime('updatedAt'),
    );
  }

  VendorModel copyWith({
    String? canteenName,
    String? logoUrl,
    String? bannerUrl,
    String? description,
    double? balanceFcfa,
    double? debtFcfa,
    bool? isActive,
    bool? isOpen,
    bool? withdrawalBlocked,
  }) {
    return VendorModel(
      id: id,
      userId: userId,
      canteenName: canteenName ?? this.canteenName,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      description: description ?? this.description,
      balanceFcfa: balanceFcfa ?? this.balanceFcfa,
      debtFcfa: debtFcfa ?? this.debtFcfa,
      isActive: isActive ?? this.isActive,
      isOpen: isOpen ?? this.isOpen,
      withdrawalBlocked: withdrawalBlocked ?? this.withdrawalBlocked,
      campuses: campuses,
      phone: phone,
      suspendedAt: suspendedAt,
      suspensionReason: suspensionReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
