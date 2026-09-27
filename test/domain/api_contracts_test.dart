import 'package:flutter_test/flutter_test.dart';
import 'package:kabakaba_vendeur/core/network/paginated.dart';
import 'package:kabakaba_vendeur/core/utils/currency_formatter.dart';
import 'package:kabakaba_vendeur/core/utils/date_labels.dart';
import 'package:kabakaba_vendeur/features/notifications/domain/app_notification.dart';
import 'package:kabakaba_vendeur/features/schedules/domain/vendor_schedule.dart';
import 'package:kabakaba_vendeur/features/withdrawals/domain/withdrawal_models.dart';
import 'package:kabakaba_vendeur/shared/models/order_model.dart';

void main() {
  group('OrderStatus.fromWire', () {
    test('garde CANCELLED_STUDENT hors de la file des nouvelles', () {
      expect(
        OrderStatus.fromWire('CANCELLED_STUDENT'),
        OrderStatus.cancelledStudent,
      );
      expect(OrderStatus.cancelledStudent.isIncoming, isFalse);
      expect(OrderStatus.cancelledStudent.isArchived, isTrue);
    });

    test('ne recycle pas un statut inconnu en pending', () {
      expect(OrderStatus.fromWire('SOMETHING_NEW'), OrderStatus.unknown);
      expect(OrderStatus.unknown.isIncoming, isFalse);
      expect(OrderStatus.unknown.isArchived, isTrue);
    });
  });

  group('WithdrawalOperator.fromWire', () {
    test('envoie les valeurs d’API, pas les libellés', () {
      expect(WithdrawalOperator.fromWire('FLOOZ'), WithdrawalOperator.flooz);
      expect(WithdrawalOperator.fromWire('MIXX'), WithdrawalOperator.mixx);
      expect(WithdrawalOperator.flooz.wireValue, 'FLOOZ');
      expect(WithdrawalOperator.mixx.wireValue, 'MIXX');
      expect(WithdrawalOperator.fromWire('T-Money'), isNull);
    });
  });

  group('VendorSchedule', () {
    test('lit une plage horaire HH:mm', () {
      final schedule = VendorSchedule.fromJson({
        'id': 'sch_1',
        'day': 'WEDNESDAY',
        'startTime': '07:30',
        'endTime': '15:00',
      });
      expect(schedule.day, Weekday.wednesday);
      expect(schedule.rangeLabel, '07:30 – 15:00');
    });
  });

  group('AppNotification', () {
    test('marque lu / non lu depuis le JSON', () {
      final unread = AppNotification.fromJson({
        'id': 'n1',
        'title': 'Nouvelle commande',
        'message': 'Riz sauce',
        'type': 'INFO',
        'isRead': false,
        'createdAt': '2026-09-27T10:00:00.000Z',
      });
      expect(unread.isRead, isFalse);
      expect(unread.type, NotificationKind.info);
    });
  });

  group('WithdrawalModel.canAppeal', () {
    test('n’est ouvert que dans la fenêtre après versement', () {
      final open = WithdrawalModel.fromJson({
        'id': 'w1',
        'amount': 5000,
        'debitedAmount': 5250,
        'operator': 'FLOOZ',
        'status': 'COMPLETED',
        'createdAt': '2026-09-27T10:00:00.000Z',
        'paidAt': '2026-09-27T10:05:00.000Z',
        'confirmationDeadlineAt': DateTime.now()
            .add(const Duration(minutes: 30))
            .toUtc()
            .toIso8601String(),
      });
      expect(open.canAppeal, isTrue);

      final closed = WithdrawalModel.fromJson({
        'id': 'w2',
        'amount': 5000,
        'operator': 'MIXX',
        'status': 'COMPLETED',
        'createdAt': '2026-09-27T10:00:00.000Z',
        'paidAt': '2026-09-27T10:05:00.000Z',
        'confirmationDeadlineAt': '2026-09-27T11:05:00.000Z',
      });
      expect(closed.canAppeal, isFalse);
    });
  });

  group('Paginated', () {
    test('lit l’enveloppe {data, meta}', () {
      final page = Paginated.fromJson({
        'data': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 21, 'totalPages': 2},
      }, (item) => item['id'] as String);
      expect(page.items, ['a', 'b']);
      expect(page.hasMore, isTrue);
      expect(page.nextPage, 2);
    });
  });

  group('formatters', () {
    test('numéro togolais vers E.164', () {
      expect(PhoneFormatter.toE164('90 12 34 56'), '+22890123456');
      expect(PhoneFormatter.toE164('+22890123456'), '+22890123456');
    });

    test('libellé de date locale', () {
      expect(formatDayMonth(DateTime(2026, 9, 27)), '27 sept.');
      expect(formatTimeHm(DateTime(2026, 9, 27, 8, 5)), '08:05');
    });
  });
}
