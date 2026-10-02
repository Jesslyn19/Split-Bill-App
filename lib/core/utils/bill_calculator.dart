import '../../models/bill_model.dart';

class BillCalculationResult {
  final Map<String, UserSplitShare> splits;
  final List<BillItem> unassignedItems;
  final double calculatedTotal;

  BillCalculationResult({
    required this.splits,
    required this.unassignedItems,
    required this.calculatedTotal,
  });
}

class BillCalculator {
  /// Computes fair proportional split for all assigned items, taxes, fees, and discounts.
  static BillCalculationResult calculate({
    required List<BillItem> items,
    required double taxAmount,
    required double serviceChargeAmount,
    required double discountAmount,
  }) {
    final Map<String, double> memberSubtotals = {};
    final List<BillItem> unassigned = [];
    double totalAssignedSubtotal = 0.0;

    // 1. Calculate each member's raw items subtotal
    for (final item in items) {
      if (item.assignedUserIds.isEmpty) {
        unassigned.add(item);
        continue;
      }

      final double perPersonPrice = item.price / item.assignedUserIds.length;
      totalAssignedSubtotal += item.price;

      for (final userId in item.assignedUserIds) {
        memberSubtotals[userId] = (memberSubtotals[userId] ?? 0.0) + perPersonPrice;
      }
    }

    if (totalAssignedSubtotal <= 0) {
      return BillCalculationResult(
        splits: {},
        unassignedItems: unassigned,
        calculatedTotal: 0.0,
      );
    }

    // 2. Proportionally distribute tax, service charge, and discounts
    final Map<String, UserSplitShare> finalSplits = {};
    double grandTotalCheck = 0.0;

    for (final entry in memberSubtotals.entries) {
      final userId = entry.key;
      final userSubtotal = entry.value;

      final double proportion = userSubtotal / totalAssignedSubtotal;
      final double userTax = proportion * taxAmount;
      final double userServiceCharge = proportion * serviceChargeAmount;
      final double userDiscount = proportion * discountAmount;

      final double rawTotal = userSubtotal + userTax + userServiceCharge - userDiscount;
      final double roundedTotal = (rawTotal * 100).roundToDouble() / 100;

      grandTotalCheck += roundedTotal;

      finalSplits[userId] = UserSplitShare(
        itemsSubtotal: (userSubtotal * 100).roundToDouble() / 100,
        taxShare: (userTax * 100).roundToDouble() / 100,
        serviceChargeShare: (userServiceCharge * 100).roundToDouble() / 100,
        discountShare: (userDiscount * 100).roundToDouble() / 100,
        totalPayable: roundedTotal > 0 ? roundedTotal : 0.0,
      );
    }

    return BillCalculationResult(
      splits: finalSplits,
      unassignedItems: unassigned,
      calculatedTotal: (grandTotalCheck * 100).roundToDouble() / 100,
    );
  }
}
