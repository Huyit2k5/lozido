import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  Future<List<Map<String, dynamic>>> parseInvoiceAdjustments(String text) async {
    if (text.trim().isEmpty) return [];

    final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
    final apiKey = doc.data()?['api_key'] ?? '';
    if (apiKey.isEmpty) throw Exception("Không tìm thấy API Key");

    final model = GenerativeModel(model: 'gemini-flash-lite-latest', apiKey: apiKey);
    final prompt = "Extract all extra charges and discounts for invoicing. Return JSON ARRAY only. No explanation.\n"
        + "Format: [{\"reason\":\"string\",\"price\":number}]\n\n"
        + "Rules:\n"
        + "1. Detect if the item is a surcharge or a discount:\n"
        + "   - Surcharge/Service (Positive): 'phí', 'thêm', 'sửa', 'thay', 'vệ sinh', 'cắt cỏ'...\n"
        + "   - Discount/Reduction (Negative): 'giảm', 'trừ', 'khuyến mãi', 'quà', 'tặng'...\n"
        + "2. If it is a discount or reduction, the price MUST be a negative number.\n"
        + "3. Units: 'k' = 1,000; 'tr' = 1,000,000.\n\n"
        + "INPUT: \"phí vệ sinh 50k với cắt cỏ 100k\"\n"
        + "[{\"reason\":\"phí vệ sinh\",\"price\":50000}, {\"reason\":\"cắt cỏ\",\"price\":100000}]\n\n"
        + "INPUT: \"thay bóng đèn 30k giảm giá sinh nhật 100k\"\n"
        + "[{\"reason\":\"thay bóng đèn\",\"price\":30000}, {\"reason\":\"giảm giá sinh nhật\",\"price\":-100000}]\n\n"
        + "INPUT: \"thêm người ở 200k trừ tiền rác 20k\"\n"
        + "[{\"reason\":\"thêm người ở\",\"price\":200000}, {\"reason\":\"tiền rác\",\"price\":-20000}]\n\n"
        + "INPUT: \"$text\"\n";

    final response = await model.generateContent([Content.text(prompt)]);
    final responseText = response.text ?? "[]";

    String cleanJson = responseText;
    if (cleanJson.contains("```json")) {
      cleanJson = cleanJson.split("```json")[1].split("```")[0].trim();
    } else if (cleanJson.contains("```")) {
      cleanJson = cleanJson.split("```")[1].split("```")[0].trim();
    }

    final List<dynamic> data = jsonDecode(cleanJson);
    return data.map((e) => e as Map<String, dynamic>).toList();
  }
}
