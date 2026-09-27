import '../../../core/network/json_reader.dart';

/// Opérateur mobile money de destination.
///
/// `wireValue` est la seule chose envoyée à l'API. Faire circuler un libellé
/// d'affichage entre écrans puis le retester par `contains()` avait pour
/// conséquence d'envoyer tous les retraits « T-Money » en `FLOOZ`.
enum WithdrawalOperator {
  flooz('FLOOZ', 'Moov Flooz'),
  mixx('MIXX', 'Mixx by Yas (T-Money)');

  final String wireValue;
  final String label;
  const WithdrawalOperator(this.wireValue, this.label);

  static WithdrawalOperator? fromWire(String? value) {
    if (value == null) return null;
    final normalized = value.toUpperCase();
    for (final operator in WithdrawalOperator.values) {
      if (operator.wireValue == normalized) return operator;
    }
    return null;
  }
}

/// Palier tarifaire appliqué, calculé par le serveur.
enum WithdrawalTier {
  under10k('UNDER_10K', 'Moins de 10 000 FCFA'),
  from10kTo30k('FROM_10K_TO_30K', 'De 10 000 à 29 999 FCFA'),
  from30k('FROM_30K', '30 000 FCFA et plus'),
  unknown('', 'Palier inconnu');

  final String wireValue;
  final String label;
  const WithdrawalTier(this.wireValue, this.label);

  static WithdrawalTier fromWire(String? value) => enumFromWire(
    value,
    WithdrawalTier.values,
    (tier) => tier.wireValue,
    fallback: WithdrawalTier.unknown,
  );
}

/// Décompte exact d'un retrait, renvoyé par `POST /withdrawals/preview`.
///
/// Indispensable avant confirmation : le montant réellement débité du solde
/// (`debitedFromBalance`) diffère du montant demandé selon le palier. Afficher
/// des frais écrits en dur dans l'UI revient à annoncer au vendeur un débit
/// qui n'est pas celui qu'il subira.
class WithdrawalRecap {
  final WithdrawalTier tier;
  final WithdrawalOperator? operator;

  /// Ce que le vendeur veut recevoir.
  final double amountRequested;

  /// Frais du barème « moins de 10 000 », à la charge du vendeur.
  final double fedapayFee;

  /// Frais de retrait cash chez l'agent.
  final double cashOutFee;

  /// Montant qui arrivera sur le compte mobile money.
  final double payoutAmountToSend;

  /// Montant réellement retiré du solde de la cantine.
  final double debitedFromBalance;

  final double vendorBorneFedapayFee;
  final double platformCost;

  /// Récapitulatif déjà rédigé par le serveur, à afficher tel quel : c'est la
  /// source de vérité sur la répartition des frais.
  final List<String> lines;

  const WithdrawalRecap({
    required this.tier,
    required this.operator,
    required this.amountRequested,
    required this.fedapayFee,
    required this.cashOutFee,
    required this.payoutAmountToSend,
    required this.debitedFromBalance,
    required this.vendorBorneFedapayFee,
    required this.platformCost,
    required this.lines,
  });

  /// Total des frais supportés par le vendeur.
  double get feesBorneByVendor => debitedFromBalance - amountRequested;

  factory WithdrawalRecap.fromJson(Map<String, dynamic> json) {
    final amountRequested = json.decimalOr('amountRequested', 0);
    return WithdrawalRecap(
      tier: WithdrawalTier.fromWire(json.optionalString('tier')),
      operator: WithdrawalOperator.fromWire(json.optionalString('operator')),
      amountRequested: amountRequested,
      fedapayFee: json.decimalOr('fedapayFee', 0),
      cashOutFee: json.decimalOr('cashOutFee', 0),
      payoutAmountToSend: json.decimalOr('payoutAmountToSend', amountRequested),
      debitedFromBalance: json.decimalOr(
        'debitedFromBalance',
        amountRequested,
      ),
      vendorBorneFedapayFee: json.decimalOr('vendorBorneFedapayFee', 0),
      platformCost: json.decimalOr('platformCost', 0),
      lines: json['lines'] is List
          ? (json['lines'] as List)
                .whereType<String>()
                .toList(growable: false)
          : const [],
    );
  }
}

enum WithdrawalStatus {
  pending('PENDING', 'En attente'),
  processing('PROCESSING', 'En cours de traitement'),
  completed('COMPLETED', 'Versé'),
  failed('FAILED', 'Échoué'),
  cancelled('CANCELLED', 'Annulé'),
  unknown('', 'Statut inconnu');

  final String wireValue;
  final String label;
  const WithdrawalStatus(this.wireValue, this.label);

  static WithdrawalStatus fromWire(String? value) => enumFromWire(
    value,
    WithdrawalStatus.values,
    (status) => status.wireValue,
    fallback: WithdrawalStatus.unknown,
  );

  bool get isSettled =>
      this == WithdrawalStatus.completed ||
      this == WithdrawalStatus.failed ||
      this == WithdrawalStatus.cancelled;
}

/// Demande de retrait, telle que listée par `GET /withdrawals/me`.
class WithdrawalModel {
  final String id;
  final double amount;
  final double debitedAmount;
  final WithdrawalOperator? operator;
  final WithdrawalStatus status;

  /// Montant effectivement envoyé à l'opérateur.
  final double? payoutAmount;
  final DateTime createdAt;
  final DateTime? paidAt;

  /// Fin de la fenêtre de réclamation ouverte après versement.
  final DateTime? confirmationDeadlineAt;
  final String? failureReason;
  final String? cancellationReason;

  const WithdrawalModel({
    required this.id,
    required this.amount,
    required this.debitedAmount,
    required this.operator,
    required this.status,
    this.payoutAmount,
    required this.createdAt,
    this.paidAt,
    this.confirmationDeadlineAt,
    this.failureReason,
    this.cancellationReason,
  });

  /// Le vendeur peut-il encore signaler un problème sur ce versement ?
  bool get canAppeal =>
      paidAt != null &&
      confirmationDeadlineAt != null &&
      confirmationDeadlineAt!.isAfter(DateTime.now());

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    final amount = json.decimalOr('amount', 0);
    return WithdrawalModel(
      id: json.requireString('id'),
      amount: amount,
      debitedAmount: json.decimalOr('debitedAmount', amount),
      operator: WithdrawalOperator.fromWire(json.optionalString('operator')),
      status: WithdrawalStatus.fromWire(json.optionalString('status')),
      payoutAmount: json.optionalDecimal('payoutAmount'),
      createdAt: json.requireDateTime('createdAt'),
      paidAt: json.optionalDateTime('paidAt'),
      confirmationDeadlineAt: json.optionalDateTime('confirmationDeadlineAt'),
      failureReason: json.optionalString('failureReason'),
      cancellationReason: json.optionalString('cancellationReason'),
    );
  }
}

/// Motif d'une réclamation sur un retrait (`POST /withdrawals/:id/appeal`).
enum WithdrawalAppealType {
  notReceived('NOT_RECEIVED', 'Je n’ai rien reçu'),
  amountMismatch('AMOUNT_MISMATCH', 'Le montant reçu ne correspond pas');

  final String wireValue;
  final String label;
  const WithdrawalAppealType(this.wireValue, this.label);
}
