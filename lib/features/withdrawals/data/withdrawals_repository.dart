import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/network/paginated.dart';
import '../domain/withdrawal_models.dart';

abstract interface class WithdrawalsRepository {
  /// Décompte exact avant confirmation, sans rien engager.
  ///
  /// Obligatoire avant `request` : le montant débité du solde dépend du
  /// palier et des frais, et seul le serveur détient le barème.
  Future<WithdrawalRecap> preview({
    required int amount,
    required WithdrawalOperator operator,
  });

  /// Crée la demande de retrait. Le solde est débité immédiatement.
  Future<WithdrawalRequestResult> request({
    required int amount,
    required WithdrawalOperator operator,
  });

  Future<Paginated<WithdrawalModel>> fetchMine({int page, int limit});

  /// Signale un problème sur un versement (fenêtre d'une heure après
  /// paiement, côté serveur).
  Future<void> appeal({
    required String withdrawalId,
    required WithdrawalAppealType type,
    required String reason,
  });
}

/// Réponse de `POST /withdrawals` : la demande, son décompte et le message
/// d'attente rédigé par le serveur.
class WithdrawalRequestResult {
  final WithdrawalModel? withdrawal;
  final WithdrawalRecap recap;
  final String message;

  const WithdrawalRequestResult({
    required this.withdrawal,
    required this.recap,
    required this.message,
  });
}

class WithdrawalsRepositoryImpl implements WithdrawalsRepository {
  final Dio _dio;

  WithdrawalsRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<WithdrawalRecap> preview({
    required int amount,
    required WithdrawalOperator operator,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.withdrawalsPreview,
        data: _payload(amount, operator),
      );
      return WithdrawalRecap.fromJson(_requireBody(response));
    });
  }

  @override
  Future<WithdrawalRequestResult> request({
    required int amount,
    required WithdrawalOperator operator,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.withdrawals,
        data: _payload(amount, operator),
      );
      final body = _requireBody(response);
      final recap = body.nested('recap');
      final withdrawal = body.nested('withdrawal');

      return WithdrawalRequestResult(
        withdrawal: withdrawal == null
            ? null
            : WithdrawalModel.fromJson(withdrawal),
        recap: recap == null
            ? WithdrawalRecap.fromJson(body)
            : WithdrawalRecap.fromJson(recap),
        message: body.stringOr(
          'message',
          'Ta demande de retrait a été enregistrée.',
        ),
      );
    });
  }

  @override
  Future<Paginated<WithdrawalModel>> fetchMine({
    int page = 1,
    int limit = 20,
  }) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.withdrawalsMine,
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Historique des retraits absent');
      }
      return Paginated.fromJson(body, WithdrawalModel.fromJson);
    });
  }

  @override
  Future<void> appeal({
    required String withdrawalId,
    required WithdrawalAppealType type,
    required String reason,
  }) {
    return guardApiCall(() async {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.withdrawalAppeal(withdrawalId),
        data: {'type': type.wireValue, 'reason': reason},
      );
    });
  }

  /// L'opérateur part toujours sous sa valeur d'API (`FLOOZ` / `MIXX`),
  /// jamais sous son libellé d'affichage.
  Map<String, Object> _payload(int amount, WithdrawalOperator operator) => {
    'amount': amount,
    'operator': operator.wireValue,
  };

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const PayloadException('Réponse de retrait vide');
    }
    return body;
  }
}

final withdrawalsRepositoryProvider = Provider<WithdrawalsRepository>((ref) {
  return WithdrawalsRepositoryImpl(ref.watch(apiClientProvider));
});

/// Décompte des frais pour un montant et un opérateur donnés.
///
/// `autoDispose` + famille : chaque combinaison est mise en cache le temps de
/// l'écran de confirmation, et libérée en sortant.
final withdrawalPreviewProvider = FutureProvider.autoDispose
    .family<WithdrawalRecap, WithdrawalDraft>((ref, draft) {
      return ref
          .watch(withdrawalsRepositoryProvider)
          .preview(amount: draft.amount, operator: draft.operator);
    });

/// Montant et opérateur choisis, transportés entre les écrans de retrait.
class WithdrawalDraft {
  final int amount;
  final WithdrawalOperator operator;

  const WithdrawalDraft({required this.amount, required this.operator});

  @override
  bool operator ==(Object other) =>
      other is WithdrawalDraft &&
      other.amount == amount &&
      other.operator == operator;

  @override
  int get hashCode => Object.hash(amount, operator);
}

final withdrawalHistoryProvider = FutureProvider<Paginated<WithdrawalModel>>((
  ref,
) {
  return ref.watch(withdrawalsRepositoryProvider).fetchMine();
});
