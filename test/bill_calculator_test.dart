import 'package:flutter_test/flutter_test.dart';
import 'package:split_bill_app/core/utils/bill_calculator.dart';
import 'package:split_bill_app/models/bill_model.dart';

void main() {
  group('BillCalculator tests', () {
    test('Calculates equal split on single shared item', () {
      final items = [
        BillItem(
          id: '1',
          name: 'Large Pizza',
          quantity: 1,
          price: 20.0,
          assignedUserIds: ['userA', 'userB'],
        ),
      ];

      final result = BillCalculator.calculate(
        items: items,
        taxAmount: 2.0,
        serviceChargeAmount: 0.0,
        discountAmount: 0.0,
      );

      expect(result.unassignedItems, isEmpty);
      expect(result.splits['userA']?.itemsSubtotal, 10.0);
      expect(result.splits['userB']?.itemsSubtotal, 10.0);
      expect(result.splits['userA']?.taxShare, 1.0);
      expect(result.splits['userB']?.taxShare, 1.0);
      expect(result.splits['userA']?.totalPayable, 11.0);
      expect(result.splits['userB']?.totalPayable, 11.0);
      expect(result.calculatedTotal, 22.0);
    });

    test('Calculates proportional tax and fee for uneven orders', () {
      // User A orders $30 steak, User B orders $10 burger. Subtotal = $40.
      // Tax = $4 (10%).
      // User A should pay $30 + (30/40 * 4) = $33.
      // User B should pay $10 + (10/40 * 4) = $11.
      final items = [
        BillItem(
          id: '1',
          name: 'Wagyu Steak',
          quantity: 1,
          price: 30.0,
          assignedUserIds: ['userA'],
        ),
        BillItem(
          id: '2',
          name: 'Cheeseburger',
          quantity: 1,
          price: 10.0,
          assignedUserIds: ['userB'],
        ),
      ];

      final result = BillCalculator.calculate(
        items: items,
        taxAmount: 4.0,
        serviceChargeAmount: 0.0,
        discountAmount: 0.0,
      );

      expect(result.splits['userA']?.totalPayable, 33.0);
      expect(result.splits['userB']?.totalPayable, 11.0);
      expect(result.calculatedTotal, 44.0);
    });

    test('Flags unassigned items', () {
      final items = [
        BillItem(
          id: '1',
          name: 'Drink',
          quantity: 1,
          price: 5.0,
          assignedUserIds: [], // unassigned
        ),
      ];

      final result = BillCalculator.calculate(
        items: items,
        taxAmount: 0.0,
        serviceChargeAmount: 0.0,
        discountAmount: 0.0,
      );

      expect(result.unassignedItems.length, 1);
      expect(result.splits, isEmpty);
    });
  });
}
