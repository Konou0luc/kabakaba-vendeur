import 'package:flutter/material.dart';

import '../../core/network/json_reader.dart';

/// Type de mouvement, enum `TransactionType` du backend.
///
/// Les valeurs sur le fil sont en `SCREAMING_SNAKE_CASE` et sont déclarées
/// explicitement : se fier à `EnumValue.name.toUpperCase()` donnait
/// `ESCROWLOCK` au lieu de `ESCROW_LOCK`, ce qui faisait échouer le parsing
/// de tout l'historique dès la première libération de séquestre — soit le
/// mouvement le plus fréquent d'un vendeur.
enum TransactionType {
  deposit('DEPOSIT', 'Recharge'),
  escrowLock('ESCROW_LOCK', 'Mise en séquestre'),
  escrowRelease('ESCROW_RELEASE', 'Commande encaissée'),
  payment('PAYMENT', 'Paiement'),
  refund('REFUND', 'Remboursement'),
  withdrawal('WITHDRAWAL', 'Retrait'),
  commission('COMMISSION', 'Commission'),
  ambassadorCommission('AMBASSADOR_COMMISSION', 'Commission ambassadeur'),
  debtRecovery('DEBT_RECOVERY', 'Récupération de créance'),
  transfer('TRANSFER', 'Transfert'),
  unknown('', 'Mouvement');

  final String wireValue;
  final String label;
  const TransactionType(this.wireValue, this.label);

  static TransactionType fromWire(String? value) => enumFromWire(
    value,
    TransactionType.values,
    (type) => type.wireValue,
    fallback: TransactionType.unknown,
  );
}

enum TransactionStatus {
  pending('PENDING', 'En attente'),
  completed('COMPLETED', 'Effectué'),
  failed('FAILED', 'Échoué'),
  unknown('', 'Inconnu');

  final String wireValue;
  final String label;
  const TransactionStatus(this.wireValue, this.label);

  static TransactionStatus fromWire(String? value) => enumFromWire(
    value,
    TransactionStatus.values,
    (status) => status.wireValue,
    fallback: TransactionStatus.unknown,
  );
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final TransactionStatus status;

  /// Montant en FCFA. Arrive en chaîne (`Decimal` Prisma), pas en nombre.
  final double amount;
  final String reference;
  final String? description;
  final String? relatedOrderId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.reference,
    this.description,
    this.relatedOrderId,
    required this.createdAt,
  });

  /// Mouvement qui augmente le solde du vendeur.
  bool get isCredit => switch (type) {
    TransactionType.escrowRelease ||
    TransactionType.deposit ||
    TransactionType.refund => true,
    _ => false,
  };

  /// Libellé affichable : la description du serveur si elle existe, sinon le
  /// type. On n'affiche jamais `reference`, qui est un UUID technique.
  String get title => description?.trim().isNotEmpty == true
      ? description!.trim()
      : type.label;

  IconData get icon => switch (type) {
    TransactionType.deposit => Icons.arrow_downward_rounded,
    TransactionType.escrowLock => Icons.lock_outline_rounded,
    TransactionType.escrowRelease => Icons.lock_open_rounded,
    TransactionType.payment => Icons.shopping_cart_rounded,
    TransactionType.refund => Icons.u_turn_left_rounded,
    TransactionType.withdrawal => Icons.account_balance_rounded,
    TransactionType.commission ||
    TransactionType.ambassadorCommission => Icons.percent_rounded,
    TransactionType.debtRecovery => Icons.money_off_rounded,
    TransactionType.transfer => Icons.swap_horiz_rounded,
    TransactionType.unknown => Icons.receipt_long_rounded,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json.requireString('id'),
      type: TransactionType.fromWire(json.optionalString('type')),
      status: TransactionStatus.fromWire(json.optionalString('status')),
      amount: json.decimalOr('amount', 0),
      reference: json.stringOr('reference', ''),
      description: json.optionalString('description'),
      relatedOrderId: json.optionalString('relatedOrderId'),
      createdAt: json.requireDateTime('createdAt'),
    );
  }
}
