import 'package:flutter/material.dart';

enum TransactionType {
  deposit('Dépôt'),
  escrowLock('Séquestre'),
  escrowRelease('Libération séquestre'),
  payment('Paiement'),
  refund('Remboursement'),
  withdrawal('Retrait'),
  commission('Commission'),
  ambassadorCommission('Commission ambassadeur'),
  debtRecovery('Remboursement de créance'),
  transfer('Transfert');

  final String label;
  const TransactionType(this.label);

  factory TransactionType.fromJson(String? json) {
    if (json == null) {
      throw const FormatException(
        'Type de transaction manquant dans la réponse API.',
      );
    }
    return TransactionType.values.firstWhere(
      (e) => e.name.toUpperCase() == json.toUpperCase(),
      orElse: () =>
          throw FormatException('Type de transaction inconnu : $json'),
    );
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed;

  factory TransactionStatus.fromJson(String? json) {
    if (json == null) {
      throw const FormatException(
        'Statut de transaction manquant dans la réponse API.',
      );
    }
    return TransactionStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == json.toUpperCase(),
      orElse: () =>
          throw FormatException('Statut de transaction inconnu : $json'),
    );
  }
}

class TransactionModel {
  final String id;
  final String? userId;
  final TransactionType type;
  final TransactionStatus status;
  final num amount;
  final String reference;
  final String? description;
  final String? relatedOrderId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TransactionModel({
    required this.id,
    this.userId,
    required this.type,
    required this.status,
    required this.amount,
    required this.reference,
    this.description,
    this.relatedOrderId,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCredit =>
      type == TransactionType.deposit ||
      type == TransactionType.escrowRelease ||
      type == TransactionType.refund ||
      type == TransactionType.commission ||
      type == TransactionType.ambassadorCommission;

  bool get isDebit =>
      type == TransactionType.payment ||
      type == TransactionType.escrowLock ||
      type == TransactionType.withdrawal ||
      type == TransactionType.debtRecovery ||
      type == TransactionType.transfer;

  IconData get icon {
    switch (type) {
      case TransactionType.deposit:
        return Icons.arrow_downward_rounded;
      case TransactionType.escrowLock:
        return Icons.lock_outline_rounded;
      case TransactionType.escrowRelease:
        return Icons.lock_open_rounded;
      case TransactionType.payment:
        return Icons.shopping_cart_rounded;
      case TransactionType.refund:
        return Icons.receipt_long_rounded;
      case TransactionType.withdrawal:
        return Icons.account_balance_rounded;
      case TransactionType.commission:
      case TransactionType.ambassadorCommission:
        return Icons.percent_rounded;
      case TransactionType.debtRecovery:
        return Icons.money_off_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: (json['id'] ?? '') as String,
        userId: json['userId'] as String?,
        type: TransactionType.fromJson(json['type'] as String?),
        status: TransactionStatus.fromJson(json['status'] as String?),
        amount: json['amount'] as num,
        reference: (json['reference'] ?? '') as String,
        description: json['description'] as String?,
        relatedOrderId: json['relatedOrderId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (userId != null) 'userId': userId,
    'type': type.name,
    'status': status.name,
    'amount': amount,
    'reference': reference,
    if (description != null) 'description': description,
    if (relatedOrderId != null) 'relatedOrderId': relatedOrderId,
    'createdAt': createdAt.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
  };
}
