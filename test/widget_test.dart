import 'package:flutter_test/flutter_test.dart';
import 'package:kabakaba_vendeur/shared/models/order_model.dart';

void main() {
  test('les libellés de statut restent stables pour l’UI vendeur', () {
    expect(OrderStatus.pending.label, 'Nouvelle');
    expect(OrderStatus.inPreparation.label, 'En préparation');
    expect(OrderStatus.cancelledStudent.label, 'Annulée par l’étudiant');
  });
}
