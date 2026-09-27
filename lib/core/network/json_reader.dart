/// La réponse de l'API ne correspond pas au contrat attendu.
///
/// Distinct d'`ApiException` : ici la requête a réussi, c'est notre lecture du
/// corps qui échoue. Le message nomme le champ fautif, ce qui évite les
/// `CastError` anonymes impossibles à diagnostiquer depuis un rapport de bug.
class PayloadException implements Exception {
  final String message;
  const PayloadException(this.message);

  @override
  String toString() => 'PayloadException: $message';
}

/// Lecture défensive mais explicite d'un corps JSON.
///
/// Deux pièges concrets de cette API motivent ces helpers :
///
/// - Prisma sérialise les `Decimal` en **chaînes** (`"1500.00"`), pas en
///   nombres. Un `json['amount'] as num` lève donc une exception sur tous les
///   montants : soldes, séquestres, retraits, transactions.
/// - Les entiers peuvent remonter en `int` ou en `double` selon le chemin de
///   sérialisation.
///
/// On accepte donc les deux formes, sans jamais inventer de valeur par défaut
/// sur un champ obligatoire : mieux vaut une erreur nommée qu'un montant
/// silencieusement remplacé par zéro.
extension JsonReader on Map<String, dynamic> {
  String requireString(String key) {
    final value = this[key];
    if (value is String && value.isNotEmpty) return value;
    throw PayloadException('Champ "$key" attendu comme texte, reçu : $value');
  }

  String? optionalString(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  String stringOr(String key, String fallback) =>
      optionalString(key) ?? fallback;

  /// Montant monétaire. Accepte `1500`, `1500.0` et `"1500.00"`.
  double requireDecimal(String key) {
    final value = _decimalOrNull(this[key]);
    if (value != null) return value;
    throw PayloadException('Champ "$key" attendu comme montant, reçu : ${this[key]}');
  }

  double decimalOr(String key, double fallback) =>
      _decimalOrNull(this[key]) ?? fallback;

  double? optionalDecimal(String key) => _decimalOrNull(this[key]);

  int requireInt(String key) {
    final value = _intOrNull(this[key]);
    if (value != null) return value;
    throw PayloadException('Champ "$key" attendu comme entier, reçu : ${this[key]}');
  }

  int intOr(String key, int fallback) => _intOrNull(this[key]) ?? fallback;

  int? optionalInt(String key) => _intOrNull(this[key]);

  bool boolOr(String key, bool fallback) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    return fallback;
  }

  DateTime requireDateTime(String key) {
    final value = optionalDateTime(key);
    if (value != null) return value;
    throw PayloadException('Champ "$key" attendu comme date ISO, reçu : ${this[key]}');
  }

  DateTime? optionalDateTime(String key) {
    final value = this[key];
    if (value is! String || value.isEmpty) return null;
    // `toLocal()` : l'API date en UTC, l'UI affiche des heures locales — sans
    // ça les statistiques d'affluence par heure sont décalées.
    return DateTime.tryParse(value)?.toLocal();
  }

  /// Objet imbriqué (`student`, `vendor`, `menuItem`…).
  Map<String, dynamic>? nested(String key) {
    final value = this[key];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  /// Liste d'objets imbriqués, vide plutôt que nulle pour simplifier l'appel.
  List<Map<String, dynamic>> nestedList(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

double? _decimalOrNull(Object? value) => switch (value) {
  final num value => value.toDouble(),
  final String value => double.tryParse(value),
  _ => null,
};

int? _intOrNull(Object? value) => switch (value) {
  final int value => value,
  final num value => value.round(),
  final String value => int.tryParse(value) ?? double.tryParse(value)?.round(),
  _ => null,
};

/// Résout une valeur d'énumération à partir de sa valeur exacte sur le fil.
///
/// On compare la chaîne du serveur à une valeur déclarée explicitement, jamais
/// à `EnumValue.name` : `escrowLock.name.toUpperCase()` vaut `ESCROWLOCK` et
/// ne correspondra jamais à `ESCROW_LOCK`.
T enumFromWire<T>(
  String? wireValue,
  List<T> values,
  String Function(T value) wireOf, {
  required T fallback,
}) {
  if (wireValue == null) return fallback;
  final normalized = wireValue.toUpperCase();
  for (final value in values) {
    if (wireOf(value).toUpperCase() == normalized) return value;
  }
  return fallback;
}
