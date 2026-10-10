import '../../core/network/json_reader.dart';

/// Statut d'une commande, tel que défini par l'enum `OrderStatus` du backend.
///
/// La valeur transmise sur le fil est déclarée explicitement : elle ne se
/// déduit pas du nom Dart (`inPreparation` → `IN_PREPARATION`).
enum OrderStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  inPreparation('IN_PREPARATION'),
  ready('READY'),
  received('RECEIVED'),
  autoReceived('AUTO_RECEIVED'),
  refused('REFUSED'),
  cancelledVendor('CANCELLED_VENDOR'),
  cancelledStudent('CANCELLED_STUDENT'),
  refunded('REFUNDED'),

  /// Statut ajouté côté serveur et pas encore connu de cette version de l'app.
  ///
  /// Indispensable : retomber sur `pending` ferait réapparaître une commande
  /// annulée dans l'onglet « Nouvelles », et le vendeur la préparerait pour
  /// rien. Une commande inconnue est rangée dans l'historique, jamais dans une
  /// file de travail.
  unknown('');

  final String wireValue;
  const OrderStatus(this.wireValue);

  static OrderStatus fromWire(String? value) => enumFromWire(
    value,
    OrderStatus.values,
    (status) => status.wireValue,
    fallback: OrderStatus.unknown,
  );

  /// Nouvelle commande à accepter ou refuser.
  bool get isIncoming => this == OrderStatus.pending;

  /// Commande en cours côté cantine.
  bool get isPreparing =>
      this == OrderStatus.accepted || this == OrderStatus.inPreparation;

  /// Prête, en attente de retrait par l'étudiant.
  bool get isReady => this == OrderStatus.ready;

  bool get isCompleted =>
      this == OrderStatus.received || this == OrderStatus.autoReceived;

  bool get isCancelledOrRefused =>
      this == OrderStatus.refused ||
      this == OrderStatus.cancelledVendor ||
      this == OrderStatus.cancelledStudent ||
      this == OrderStatus.refunded;

  /// Tout ce qui n'est plus actionnable par le vendeur.
  bool get isArchived =>
      isCompleted || isCancelledOrRefused || this == OrderStatus.unknown;

  String get label => switch (this) {
    OrderStatus.pending => 'Nouvelle',
    OrderStatus.accepted => 'Acceptée',
    OrderStatus.inPreparation => 'En préparation',
    OrderStatus.ready => 'Prête',
    OrderStatus.received => 'Reçue',
    OrderStatus.autoReceived => 'Reçue (auto)',
    OrderStatus.refused => 'Refusée',
    OrderStatus.cancelledVendor => 'Annulée par toi',
    OrderStatus.cancelledStudent => 'Annulée par l’étudiant',
    OrderStatus.refunded => 'Remboursée',
    OrderStatus.unknown => 'Statut inconnu',
  };
}

/// Transitions que le backend autorise au vendeur (`OrdersService.update`).
///
/// Déclarées ici pour que l'UI ne propose jamais une action vouée à un 403 :
/// « Marquer reçue » par exemple est réservé à l'admin, la réception réelle
/// se faisant par `AUTO_RECEIVED` une heure après le passage en `READY`.
extension VendorOrderActions on OrderStatus {
  bool get canAccept => this == OrderStatus.pending;
  bool get canRefuse => this == OrderStatus.pending;
  bool get canStartPreparing => this == OrderStatus.accepted;
  bool get canMarkReady => this == OrderStatus.inPreparation;
  bool get canCancel =>
      this == OrderStatus.pending ||
      this == OrderStatus.accepted ||
      this == OrderStatus.inPreparation;

  /// Le remboursement n'est ouvert qu'après remise (il débite le solde du
  /// vendeur, contrairement à un refus qui recrédite simplement l'étudiant).
  bool get canRefund =>
      this == OrderStatus.ready ||
      this == OrderStatus.received ||
      this == OrderStatus.autoReceived;
}

class OrderItemModel {
  final String id;
  final String menuItemId;
  final String name;
  final int quantity;

  /// Prix unitaire en tickets, figé à la commande.
  final int unitPriceTickets;

  const OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPriceTickets,
  });

  int get lineTotalTickets => quantity * unitPriceTickets;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json.stringOr('id', ''),
      menuItemId: json.stringOr('itemId', ''),
      // `GET /orders` n'inclut que `menuItem: { name }`.
      name: json.nested('menuItem')?.stringOr('name', 'Article') ?? 'Article',
      quantity: json.intOr('quantity', 1),
      unitPriceTickets: json.intOr('unitPrice', 0),
    );
  }
}

class OrderModel {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentCampusName;
  final String vendorId;
  final OrderStatus status;
  final int totalTickets;

  /// Montant en FCFA mis en séquestre, libéré au passage en `READY`.
  final double escrowAmount;
  final List<OrderItemModel> items;

  /// Nom de l'option d'emballage choisie (« Sur place », « À emporter »…),
  /// tel que configuré par le vendeur dans son catalogue. `null` quand la
  /// commande n'en porte pas.
  final String? packagingName;

  /// Motif de refus, d'annulation, de remboursement, ou message « prête ».
  final String? reason;
  final String? pickupCode;
  final DateTime createdAt;
  final DateTime? readyAt;
  final DateTime? confirmedAt;

  const OrderModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentCampusName,
    required this.vendorId,
    required this.status,
    required this.totalTickets,
    required this.escrowAmount,
    required this.items,
    this.packagingName,
    this.reason,
    this.pickupCode,
    required this.createdAt,
    this.readyAt,
    this.confirmedAt,
  });

  /// Numéro à communiquer à la récupération.
  String get displayCode {
    final code = pickupCode?.trim();
    if (code != null && code.isNotEmpty) return code.toUpperCase();
    return shortReference;
  }

  /// Référence courte affichable, l'`id` étant un UUID.
  String get shortReference => id.length <= 6
      ? id.toUpperCase()
      : id.substring(0, 6).toUpperCase();

  int get totalArticles =>
      items.fold(0, (total, item) => total + item.quantity);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final student = json.nested('student');

    return OrderModel(
      id: json.requireString('id'),
      studentId: json.stringOr('studentId', ''),
      studentName: _studentName(student),
      studentCampusName: student?.nested('campus')?.optionalString('name'),
      vendorId: json.stringOr('vendorId', ''),
      status: OrderStatus.fromWire(json.optionalString('status')),
      totalTickets: json.intOr('totalTickets', 0),
      escrowAmount: json.decimalOr('escrowAmount', 0),
      items: json
          .nestedList('items')
          .map(OrderItemModel.fromJson)
          .toList(growable: false),
      packagingName: json.nested('packagingOption')?.optionalString('name'),
      reason: json.optionalString('reason'),
      pickupCode: json.optionalString('pickupCode'),
      createdAt: json.requireDateTime('createdAt'),
      readyAt: json.optionalDateTime('readyAt'),
      confirmedAt: json.optionalDateTime('confirmedAt'),
    );
  }

  static String _studentName(Map<String, dynamic>? student) {
    if (student == null) return 'Étudiant';
    final parts = [
      student.optionalString('firstName'),
      student.optionalString('lastName'),
    ].whereType<String>();
    final name = parts.join(' ').trim();
    return name.isEmpty ? 'Étudiant' : name;
  }

  OrderModel copyWith({OrderStatus? status, String? reason}) {
    return OrderModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentCampusName: studentCampusName,
      vendorId: vendorId,
      status: status ?? this.status,
      totalTickets: totalTickets,
      escrowAmount: escrowAmount,
      items: items,
      packagingName: packagingName,
      reason: reason ?? this.reason,
      pickupCode: pickupCode,
      createdAt: createdAt,
      readyAt: readyAt,
      confirmedAt: confirmedAt,
    );
  }
}
