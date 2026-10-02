import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bill_calculator.dart';
import '../../models/bill_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class BillSummaryScreen extends StatefulWidget {
  final String groupId;
  final String billTitle;
  final List<BillItem> items;
  final List<AppUser> groupMembers;
  final double taxAmount;
  final double serviceChargeAmount;
  final double discountAmount;
  final String currentUserId;
  final BillCalculationResult calculationResult;

  const BillSummaryScreen({
    super.key,
    required this.groupId,
    required this.billTitle,
    required this.items,
    required this.groupMembers,
    required this.taxAmount,
    required this.serviceChargeAmount,
    required this.discountAmount,
    required this.currentUserId,
    required this.calculationResult,
  });

  @override
  State<BillSummaryScreen> createState() => _BillSummaryScreenState();
}

class _BillSummaryScreenState extends State<BillSummaryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  String _formatSummaryText() {
    final buffer = StringBuffer();
    buffer.writeln('🧾 *Bill Breakdown: ${widget.billTitle}*');
    buffer.writeln('--------------------------------');

    for (final member in widget.groupMembers) {
      final split = widget.calculationResult.splits[member.uid];
      if (split != null && split.totalPayable > 0) {
        buffer.writeln('👤 *${member.displayName}*: \$${split.totalPayable.toStringAsFixed(2)}');
        buffer.writeln('   Items: \$${split.itemsSubtotal.toStringAsFixed(2)} | Tax/Fee: \$${(split.taxShare + split.serviceChargeShare - split.discountShare).toStringAsFixed(2)}');
      }
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Total: \$${widget.calculationResult.calculatedTotal.toStringAsFixed(2)}');
    return buffer.toString();
  }

  Future<void> _saveAndNotify() async {
    setState(() => _isSaving = true);
    try {
      final bill = Bill(
        id: const Uuid().v4(),
        groupId: widget.groupId,
        title: widget.billTitle,
        paidByUserId: widget.currentUserId,
        subtotal: widget.items.fold(0.0, (sum, i) => sum + i.price),
        taxAmount: widget.taxAmount,
        serviceChargeAmount: widget.serviceChargeAmount,
        discountAmount: widget.discountAmount,
        totalAmount: widget.calculationResult.calculatedTotal,
        status: 'assigned', // triggers the Cloud Function to send FCM notifications
        items: widget.items,
        splits: widget.calculationResult.splits,
        createdAt: DateTime.now(),
      );

      await _firestoreService.saveBill(bill);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill saved! Push notifications sent to members.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back to the home or group screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving bill: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Summary'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share via WhatsApp / Other apps',
            onPressed: () {
              Share.share(_formatSummaryText(), subject: 'Split Bill - ${widget.billTitle}');
            },
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.primary.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.billTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tax: \$${widget.taxAmount.toStringAsFixed(2)} | Fee: \$${widget.serviceChargeAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        '\$${widget.calculationResult.calculatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.groupMembers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = widget.groupMembers[index];
                      final split = widget.calculationResult.splits[member.uid];

                      final totalOwed = split?.totalPayable ?? 0.0;
                      final itemsShare = split?.itemsSubtotal ?? 0.0;
                      final extras = ((split?.taxShare ?? 0.0) +
                          (split?.serviceChargeShare ?? 0.0) -
                          (split?.discountShare ?? 0.0));

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.15),
                                child: Text(
                                  member.displayName.isNotEmpty
                                      ? member.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.displayName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Items: \$${itemsShare.toStringAsFixed(2)} + Tax/Fees: \$${extras.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${totalOwed.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.notifications_active, color: Colors.white),
                        label: const Text(
                          'Save & Send Notification to Members',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onPressed: _saveAndNotify,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
