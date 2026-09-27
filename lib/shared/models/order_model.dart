enum OrderStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  inPreparation('IN_PREPARATION'),
  ready('READY'),
  received('RECEIVED'),
  autoReceived('AUTO_RECEIVED'),
  refused('REFUSED'),
  cancelledVendor('CANCELLED_VENDOR'),
  refunded('REFUNDED');

  final String value;
  const OrderStatus(this.value);

  factory OrderStatus.fromJson(String? json) {
    if (json == null) return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (e) => e.value == json.toUpperCase(),
      orElse: () => OrderStatus.pending,
    );
  }

  String toJson() => value;

  bool get isIncoming => this == OrderStatus.pending;

  bool get isPreparing =>
      this == OrderStatus.accepted || this == OrderStatus.inPreparation;

  bool get isReady => this == OrderStatus.ready;

  bool get isCompleted =>
      this == OrderStatus.received ||
      this == OrderStatus.autoReceived ||
      this == OrderStatus.refunded;

  bool get isCancelledOrRefused =>
      this == OrderStatus.refused ||
      this == OrderStatus.cancelledVendor ||
      this == OrderStatus.refunded;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Nouvelle';
      case OrderStatus.accepted:
        return 'Acceptée';
      case OrderStatus.inPreparation:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.received:
        return 'Reçue';
      case OrderStatus.autoReceived:
        return 'Reçue (auto)';
      case OrderStatus.refused:
        return 'Refusée';
      case OrderStatus.cancelledVendor:
        return 'Annulée';
      case OrderStatus.refunded:
        return 'Remboursée';
    }
  }
}

enum PackagingType {
  onSite('Sur place'),
  takeaway('À emporter'),
  delivery('À domicile');

  final String label;
  const PackagingType(this.label);

  factory PackagingType.fromJson(dynamic json) {
    if (json is String) {
      return PackagingType.values.firstWhere(
        (e) => e.name.toLowerCase() == json.toLowerCase(),
        orElse: () => PackagingType.onSite,
      );
    }
    final intVal = int.tryParse(json.toString());
    if (intVal != null && intVal < PackagingType.values.length) {
      return PackagingType.values[intVal];
    }
    return PackagingType.onSite;
  }
}

class OrderItemModel {
  final String id;
  final String name;
  final int quantity;
  final int unitPrice;
  final String? imageUrl;

  const OrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    id: (json['id'] ?? json['itemId']) as String? ?? '',
    name:
        (json['name'] ?? (json['menuItem'] as Map?)?['name'] ?? 'Article')
            as String,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
    imageUrl:
        json['imageUrl'] as String? ??
        (json['menuItem'] as Map?)?['imageUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

class OrderModel {
  final String id;
  final String orderId;
  final String studentName;
  final String studentId;
  final String vendorId;
  final OrderStatus status;
  final int totalTickets;
  final double escrowAmount;
  final List<OrderItemModel> items;
  final PackagingType? packaging;
  final String? refusalReason;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? confirmedAt;

  const OrderModel({
    required this.id,
    this.orderId = '',
    required this.studentName,
    required this.studentId,
    required this.vendorId,
    required this.status,
    required this.totalTickets,
    required this.escrowAmount,
    required this.items,
    this.packaging,
    this.refusalReason,
    required this.createdAt,
    this.acceptedAt,
    this.readyAt,
    this.confirmedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    PackagingType? packaging;
    if (json['packagingType'] != null) {
      packaging = PackagingType.fromJson(json['packagingType']);
    }
    if (packaging == null && json['packagingOptionId'] != null) {
      packaging = PackagingType.takeaway;
    }

    return OrderModel(
      id: (json['id'] ?? '') as String,
      orderId: (json['orderId'] ?? json['id'] ?? '') as String,
      studentName:
          (json['studentName'] ??
                  (json['student'] as Map?)?['name'] ??
                  _studentName(json['student']) ??
                  'Étudiant')
              as String,
      studentId: (json['studentId'] ?? '') as String,
      vendorId: (json['vendorId'] ?? '') as String,
      status: OrderStatus.fromJson(json['status'] as String?),
      totalTickets: (json['totalTickets'] as num?)?.toInt() ?? 0,
      escrowAmount: (json['escrowAmount'] as num?)?.toDouble() ?? 0.0,
      items: items,
      packaging: packaging,
      refusalReason:
          json['reason'] as String? ?? json['refusalReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.tryParse(json['readyAt'] as String)
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'] as String)
          : null,
    );
  }

  static String? _studentName(dynamic value) {
    if (value is! Map) return null;
    final firstName = value['firstName'] as String?;
    final lastName = value['lastName'] as String?;
    final name = [
      firstName,
      lastName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return name.isEmpty ? null : name;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentName': studentName,
    'studentId': studentId,
    'vendorId': vendorId,
    'status': status.toJson(),
    'totalTickets': totalTickets,
    'escrowAmount': escrowAmount,
    'items': items.map((e) => e.toJson()).toList(),
    'packaging': packaging?.name,
    if (refusalReason != null) 'refusalReason': refusalReason,
    'createdAt': createdAt.toIso8601String(),
    if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
    if (readyAt != null) 'readyAt': readyAt!.toIso8601String(),
    if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
  };

  OrderModel copyWith({
    OrderStatus? status,
    String? refusalReason,
    DateTime? acceptedAt,
    DateTime? readyAt,
    DateTime? confirmedAt,
  }) {
    return OrderModel(
      id: id,
      orderId: orderId,
      studentName: studentName,
      studentId: studentId,
      vendorId: vendorId,
      status: status ?? this.status,
      totalTickets: totalTickets,
      escrowAmount: escrowAmount,
      items: items,
      packaging: packaging,
      refusalReason: refusalReason ?? this.refusalReason,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      readyAt: readyAt ?? this.readyAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
