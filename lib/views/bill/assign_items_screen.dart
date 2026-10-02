import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bill_calculator.dart';
import '../../models/bill_model.dart';
import '../../models/user_model.dart';
import 'bill_summary_screen.dart';

class AssignItemsScreen extends StatefulWidget {
  final String groupId;
  final String billTitle;
  final List<BillItem> initialItems;
  final List<AppUser> groupMembers;
  final double taxAmount;
  final double serviceChargeAmount;
  final double discountAmount;
  final String currentUserId;

  const AssignItemsScreen({
    super.key,
    required this.groupId,
    required this.billTitle,
    required this.initialItems,
    required this.groupMembers,
    required this.taxAmount,
    required this.serviceChargeAmount,
    required this.discountAmount,
    required this.currentUserId,
  });

  @override
  State<AssignItemsScreen> createState() => _AssignItemsScreenState();
}

class _AssignItemsScreenState extends State<AssignItemsScreen> {
  late List<BillItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  void _toggleUserAssignment(int itemIndex, String userId) {
    setState(() {
      final currentItem = _items[itemIndex];
      final currentAssigned = List<String>.from(currentItem.assignedUserIds);

      if (currentAssigned.contains(userId)) {
        currentAssigned.remove(userId);
      } else {
        currentAssigned.add(userId);
      }

      _items[itemIndex] = currentItem.copyWith(assignedUserIds: currentAssigned);
    });
  }

  void _assignAllMembers(int itemIndex) {
    setState(() {
      final allUserIds = widget.groupMembers.map((m) => m.uid).toList();
      _items[itemIndex] = _items[itemIndex].copyWith(assignedUserIds: allUserIds);
    });
  }

  void _clearAssignments(int itemIndex) {
    setState(() {
      _items[itemIndex] = _items[itemIndex].copyWith(assignedUserIds: []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final calcResult = BillCalculator.calculate(
      items: _items,
      taxAmount: widget.taxAmount,
      serviceChargeAmount: widget.serviceChargeAmount,
      discountAmount: widget.discountAmount,
    );

    final unassignedCount = calcResult.unassignedItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.billTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner for unassigned items warning
          if (unassignedCount > 0)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$unassignedCount item(s) unassigned. Tap members to assign.',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x  ${item.name}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Who shared this?',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),

                        // Member Selection Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.groupMembers.map((member) {
                            final isAssigned = item.assignedUserIds.contains(member.uid);
                            return FilterChip(
                              label: Text(member.displayName),
                              selected: isAssigned,
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                              onSelected: (_) => _toggleUserAssignment(index, member.uid),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _assignAllMembers(index),
                              child: const Text('All', style: TextStyle(fontSize: 12)),
                            ),
                            TextButton(
                              onPressed: () => _clearAssignments(index),
                              child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Bar: Proceed to review
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                )
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BillSummaryScreen(
                          groupId: widget.groupId,
                          billTitle: widget.billTitle,
                          items: _items,
                          groupMembers: widget.groupMembers,
                          taxAmount: widget.taxAmount,
                          serviceChargeAmount: widget.serviceChargeAmount,
                          discountAmount: widget.discountAmount,
                          currentUserId: widget.currentUserId,
                          calculationResult: calcResult,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Review & Finalize Split',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
