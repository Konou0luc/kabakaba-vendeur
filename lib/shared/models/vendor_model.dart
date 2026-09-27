class VendorModel {
  final String id;
  final String userId;
  final String canteenName;
  final String? logoUrl;
  final String? bannerUrl;
  final String? description;
  final double balanceFcfa;
  final double debtFcfa;
  final bool isActive;
  final bool isOpen;
  final String campusId;
  final String campusName;
  final String? phone;
  final String? address;
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
    required this.campusId,
    required this.campusName,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    final parts = canteenName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
    id: (json['id'] ?? json['vendorId']) as String,
    userId: (json['userId'] ?? '') as String,
    canteenName: (json['canteenName'] ?? json['name']) as String,
    logoUrl: json['logoUrl'] as String?,
    bannerUrl: json['bannerUrl'] as String?,
    description: json['description'] as String?,
    balanceFcfa: (json['balanceFcfa'] as num).toDouble(),
    debtFcfa: (json['debtFcfa'] as num).toDouble(),
    isActive: (json['isActive'] ?? json['isAvailable']) as bool,
    isOpen: json['isOpen'] as bool,
    campusId: (json['campusId'] ?? '') as String,
    campusName: _campusNameFromJson(json),
    phone:
        json['phone'] as String? ?? (json['user'] as Map?)?['phone'] as String?,
    address: json['address'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static String _campusNameFromJson(Map<String, dynamic> json) {
    final campuses = json['campuses'];
    final firstCampus = campuses is List && campuses.isNotEmpty
        ? campuses.first
        : null;
    return (json['campusName'] ??
            (json['campus'] as Map?)?['name'] ??
            (firstCampus as Map?)?['name'] ??
            '')
        as String;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'canteenName': canteenName,
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (bannerUrl != null) 'bannerUrl': bannerUrl,
    if (description != null) 'description': description,
    'balanceFcfa': balanceFcfa,
    'debtFcfa': debtFcfa,
    'isActive': isActive,
    'isOpen': isOpen,
    'campusId': campusId,
    'campusName': campusName,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  VendorModel copyWith({
    String? id,
    String? userId,
    String? canteenName,
    String? logoUrl,
    String? bannerUrl,
    String? description,
    double? balanceFcfa,
    double? debtFcfa,
    bool? isActive,
    bool? isOpen,
    String? campusId,
    String? campusName,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      canteenName: canteenName ?? this.canteenName,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      description: description ?? this.description,
      balanceFcfa: balanceFcfa ?? this.balanceFcfa,
      debtFcfa: debtFcfa ?? this.debtFcfa,
      isActive: isActive ?? this.isActive,
      isOpen: isOpen ?? this.isOpen,
      campusId: campusId ?? this.campusId,
      campusName: campusName ?? this.campusName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
