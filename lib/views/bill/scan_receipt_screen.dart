import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bill_model.dart';
import '../../models/user_model.dart';
import '../../services/receipt_scanner_service.dart';
import 'assign_items_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  final String groupId;
  final List<AppUser> groupMembers;
  final String currentUserId;

  const ScanReceiptScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
    required this.currentUserId,
  });

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _picker = ImagePicker();
  final _scannerService = ReceiptScannerService();

  File? _selectedImage;
  bool _isScanning = false;
  String _billTitle = 'Dinner Bill';

  List<BillItem> _parsedItems = [];
  double _taxAmount = 0.0;
  double _serviceChargeAmount = 0.0;
  double _discountAmount = 0.0;

  // Securely loaded at build time via --dart-define=GEMINI_API_KEY=your_key
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _processReceipt();
    }
  }

  Future<void> _processReceipt() async {
    if (_selectedImage == null) return;
    setState(() => _isScanning = true);

    try {
      ParsedReceiptResult result;
      // If Gemini API Key is provided, use AI parsing; otherwise use ML Kit
      if (_geminiApiKey.isNotEmpty) {
        result = await _scannerService.parseWithGemini(
          imageFile: _selectedImage!,
          apiKey: _geminiApiKey,
        );
      } else {
        result = await _scannerService.parseWithMLKit(_selectedImage!);
      }

      setState(() {
        _parsedItems = result.items;
        _taxAmount = result.tax;
        _serviceChargeAmount = result.serviceCharge;
        _discountAmount = result.discount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanning failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _addNewManualItem() {
    setState(() {
      _parsedItems.add(
        BillItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New Item',
          quantity: 1,
          price: 0.0,
          assignedUserIds: [],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan or Create Bill'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Title Input
            TextField(
              decoration: const InputDecoration(
                labelText: 'Bill Title',
                hintText: 'e.g. Saturday Dinner at Mario\'s',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _billTitle = val,
            ),
            const SizedBox(height: 16),

            // Camera / Gallery Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isScanning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Scanning receipt & detecting line items...'),
                    ],
                  ),
                ),
              ),

            // Items List
            if (_parsedItems.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Receipt Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    onPressed: _addNewManualItem,
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _parsedItems.length,
                itemBuilder: (context, index) {
                  final item = _parsedItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: item.name,
                              decoration: const InputDecoration(labelText: 'Item Name', border: InputBorder.none),
                              onChanged: (val) {
                                _parsedItems[index] = item.copyWith(name: val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.price.toStringAsFixed(2),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Price (\$)', border: InputBorder.none),
                              onChanged: (val) {
                                final price = double.tryParse(val) ?? 0.0;
                                _parsedItems[index] = item.copyWith(price: price);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() => _parsedItems.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Tax, Service Charge, Discount
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _taxAmount.toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Tax (\$)', border: OutlineInputBorder()),
                      onChanged: (val) => _taxAmount = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: _serviceChargeAmount.toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Service Charge (\$)', border: OutlineInputBorder()),
                      onChanged: (val) => _serviceChargeAmount = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_parsedItems.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignItemsScreen(
                          groupId: widget.groupId,
                          billTitle: _billTitle,
                          initialItems: _parsedItems,
                          groupMembers: widget.groupMembers,
                          taxAmount: _taxAmount,
                          serviceChargeAmount: _serviceChargeAmount,
                          discountAmount: _discountAmount,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Next: Assign Items to People',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
