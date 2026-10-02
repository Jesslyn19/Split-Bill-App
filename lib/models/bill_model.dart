class BillItem {
  final String id;
  final String name;
  final int quantity;
  final double price; // Total price for this line item
  final List<String> assignedUserIds;

  BillItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.assignedUserIds,
  });

  BillItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    List<String>? assignedUserIds,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'assignedUserIds': assignedUserIds,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      assignedUserIds: List<String>.from(map['assignedUserIds'] ?? []),
    );
  }
}

class UserSplitShare {
  final double itemsSubtotal;
  final double taxShare;
  final double serviceChargeShare;
  final double discountShare;
  final double totalPayable;
  final bool isPaid;

  UserSplitShare({
    required this.itemsSubtotal,
    required this.taxShare,
    required this.serviceChargeShare,
    required this.discountShare,
    required this.totalPayable,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemsSubtotal': itemsSubtotal,
      'taxShare': taxShare,
      'serviceChargeShare': serviceChargeShare,
      'discountShare': discountShare,
      'totalPayable': totalPayable,
      'isPaid': isPaid,
    };
  }

  factory UserSplitShare.fromMap(Map<String, dynamic> map) {
    return UserSplitShare(
      itemsSubtotal: (map['itemsSubtotal'] as num?)?.toDouble() ?? 0.0,
      taxShare: (map['taxShare'] as num?)?.toDouble() ?? 0.0,
      serviceChargeShare: (map['serviceChargeShare'] as num?)?.toDouble() ?? 0.0,
      discountShare: (map['discountShare'] as num?)?.toDouble() ?? 0.0,
      totalPayable: (map['totalPayable'] as num?)?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] ?? false,
    );
  }
}

class Bill {
  final String id;
  final String groupId;
  final String title;
  final String? receiptImageUrl;
  final String paidByUserId;
  final double subtotal;
  final double taxAmount;
  final double serviceChargeAmount;
  final double discountAmount;
  final double totalAmount;
  final String status; // 'draft', 'assigned', 'settled'
  final List<BillItem> items;
  final Map<String, UserSplitShare> splits;
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.groupId,
    required this.title,
    this.receiptImageUrl,
    required this.paidByUserId,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceChargeAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.splits,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'receiptImageUrl': receiptImageUrl,
      'paidByUserId': paidByUserId,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'serviceChargeAmount': serviceChargeAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'status': status,
      'items': items.map((i) => i.toMap()).toList(),
      'splits': splits.map((key, value) => MapEntry(key, value.toMap())),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, String docId) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => BillItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    final rawSplits = map['splits'] as Map<String, dynamic>? ?? {};
    final splitsMap = rawSplits.map((key, value) => MapEntry(
          key,
          UserSplitShare.fromMap(Map<String, dynamic>.from(value)),
        ));

    return Bill(
      id: docId,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? 'Bill',
      receiptImageUrl: map['receiptImageUrl'],
      paidByUserId: map['paidByUserId'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      serviceChargeAmount: (map['serviceChargeAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'draft',
      items: itemsList,
      splits: splitsMap,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}
