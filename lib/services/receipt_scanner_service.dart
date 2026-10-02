import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_model.dart';

class ParsedReceiptResult {
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double discount;
  final double total;

  ParsedReceiptResult({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.discount,
    required this.total,
  });
}

class ReceiptScannerService {
  final _uuid = const Uuid();

  /// Parse receipt using Gemini 1.5 Flash (highest accuracy for unstructured receipts)
  Future<ParsedReceiptResult> parseWithGemini({
    required File imageFile,
    required String apiKey,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final imageBytes = await imageFile.readAsBytes();
    final prompt = TextPart('''
Analyze this receipt image and extract all purchased line items and financial totals.
Return ONLY valid JSON matching this schema:
{
  "items": [
    {"name": "Item Name", "quantity": 1, "price": 10.50}
  ],
  "subtotal": 10.50,
  "tax": 1.05,
  "serviceCharge": 0.00,
  "discount": 0.00,
  "total": 11.55
}
Ensure item prices are numbers (e.g. 12.50 not "\$12.50").
''');

    final response = await model.generateContent([
      Content.multi([
        prompt,
        DataPart('image/jpeg', imageBytes),
      ]),
    ]);

    final rawJson = response.text ?? '{}';
    final data = jsonDecode(rawJson) as Map<String, dynamic>;

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((item) {
      return BillItem(
        id: _uuid.v4(),
        name: item['name']?.toString() ?? 'Item',
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        price: (item['price'] as num?)?.toDouble() ?? 0.0,
        assignedUserIds: [],
      );
    }).toList();

    return ParsedReceiptResult(
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (data['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// On-device offline fallback using Google ML Kit
  Future<ParsedReceiptResult> parseWithMLKit(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final List<BillItem> extractedItems = [];
    final priceRegex = RegExp(r'(\d+[\.,]\d{2})');

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        final match = priceRegex.firstMatch(text);
        if (match != null) {
          final priceString = match.group(1)!.replaceAll(',', '.');
          final price = double.tryParse(priceString) ?? 0.0;
          final itemName = text.replaceAll(match.group(0)!, '').trim();

          if (itemName.isNotEmpty && price > 0) {
            extractedItems.add(
              BillItem(
                id: _uuid.v4(),
                name: itemName,
                quantity: 1,
                price: price,
                assignedUserIds: [],
              ),
            );
          }
        }
      }
    }

    final double calculatedSubtotal = extractedItems.fold(0.0, (sum, i) => sum + i.price);

    return ParsedReceiptResult(
      items: extractedItems,
      subtotal: calculatedSubtotal,
      tax: 0.0,
      serviceCharge: 0.0,
      discount: 0.0,
      total: calculatedSubtotal,
    );
  }
}
