import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  Future<List<Map<String, dynamic>>> parseInvoiceAdjustments(String text, {int occupantsCount = 1, double rentPrice = 0}) async {
    if (text.trim().isEmpty) return [];

    final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
    final apiKey = doc.data()?['api_key'] ?? '';
    if (apiKey.isEmpty) throw Exception("Không tìm thấy API Key");

    final model = GenerativeModel(model: 'gemini-flash-lite-latest', apiKey: apiKey);
    final prompt = "Extract all extra charges and discounts for invoicing. Return JSON ARRAY only. No explanation.\n"
        + "Format: [{\"reason\":\"string\",\"price\":number}]\n\n"
        + "Context:\n"
        + "- Number of occupants in the room: $occupantsCount\n"
        + "- Monthly Rent Price: ${rentPrice.toStringAsFixed(0)} VND\n\n"
        + "Rules:\n"
        + "1. Detect if the item is a surcharge or a discount:\n"
        + "   - Surcharge/Service (Positive): 'phí', 'thêm', 'sửa', 'thay', 'vệ sinh', 'cắt cỏ'...\n"
        + "   - Discount/Reduction (Negative): 'giảm', 'trừ', 'khuyến mãi', 'quà', 'tặng'...\n"
        + "2. If it is a discount or reduction, the price MUST be a negative number.\n"
        + "3. Units: 'k' = 1,000; 'tr' = 1,000,000.\n"
        + "4. **OCCUPANTS**: If input mentions 'per person' (mỗi người, 1 người, đầu người...), multiply unit price by $occupantsCount.\n"
        + "5. **PERCENTAGES**: If input mentions percentages (%, phần trăm), calculate it based on the Monthly Rent Price ($rentPrice). Example: 'giảm 10%' = ${-0.1 * rentPrice}.\n"
        + "6. **MISSING PRICE**: If a reason is clear but no price/percentage is found, return \"price\": 0.\n\n"
        + "INPUT: \"phí vệ sinh 50k với cắt cỏ 100k\"\n"
        + "[{\"reason\":\"phí vệ sinh\",\"price\":50000}, {\"reason\":\"cắt cỏ\",\"price\":100000}]\n\n"
        + "INPUT: \"giảm giá khách quen 10%\"\n"
        + "[{\"reason\":\"khách quen\",\"price\":${-0.1 * rentPrice}}]\n\n"
        + "INPUT: \"giữ xe 100k 1 người\"\n"
        + "[{\"reason\":\"giữ xe ($occupantsCount người)\",\"price\":${100000 * occupantsCount}}]\n\n"
        + "INPUT: \"Thay bóng đèn\"\n"
        + "[{\"reason\":\"Thay bóng đèn\",\"price\":0}]\n\n"
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

  Future<Map<String, dynamic>> parseContractDocument(Uint8List bytes, String mimeType) async {
    final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
    final apiKey = doc.data()?['api_key'] ?? '';
    if (apiKey.isEmpty) throw Exception("Không tìm thấy API Key");

    final model = GenerativeModel(model: 'gemini-flash-lite-latest', apiKey: apiKey);
    
    final prompt = """
Bạn là một AI chuyên trích xuất dữ liệu từ Hợp đồng thuê phòng trọ hoặc hình ảnh Căn cước công dân.
Hãy đọc tài liệu được đính kèm và trích xuất các thông tin sau, trả về duy nhất một object JSON. Không có bất kỳ đoạn giải thích hay text nào khác.

Định dạng JSON cần trả về:
{
  "tenantName": "string (Họ và tên khách thuê / Bên B)",
  "phoneNumber": "string (Số điện thoại khách thuê)",
  "gender": "string (Nam hoặc Nữ)",
  "birthYear": "string (Ngày sinh hoặc năm sinh. VD: 16/06/1990)",
  "cccd": "string (Số CMND/CCCD/Passport)",
  "issueDate": "string (Ngày cấp CCCD)",
  "issuePlace": "string (Nơi cấp CCCD)",
  "duration": "string (Thời hạn thuê, ví dụ: '6 Tháng', '1 Năm')",
  "startDate": "string (Ngày bắt đầu thuê, ví dụ: '18/04/2026')",
  "rentPrice": "number (Giá tiền thuê phòng trọ tính theo VNĐ, chỉ để số, VD: 15000000)",
  "depositAmount": "number (Tiền thế chân / cọc tính theo VNĐ, chỉ để số, VD: 0)",
  "billingDate": "string (Ngày thanh toán hàng tháng, VD: '1' hoặc '15')",
  "electricityPrice": "number (Tiền điện, VD: 3500)",
  "waterPrice": "number (Tiền nước, VD: 20000)"
}

Lưu ý:
- Nếu thông tin nào không có trong tài liệu, hãy để null hoặc chuỗi rỗng "".
- Với giá tiền, hãy bỏ các ký tự "đ", ".", "," và chuyển thành số nguyên. Ví dụ "15.000.000đ" -> 15000000.
- Ngày tháng cố gắng format theo dạng "dd/MM/yyyy" hoặc giữ nguyên số ngày (ví dụ thanh toán vào ngày "1 dương lịch" -> "1").
""";

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, bytes),
      ])
    ];

    final response = await model.generateContent(content);
    final responseText = response.text ?? "{}";

    String cleanJson = responseText;
    if (cleanJson.contains("```json")) {
      cleanJson = cleanJson.split("```json")[1].split("```")[0].trim();
    } else if (cleanJson.contains("```")) {
      cleanJson = cleanJson.split("```")[1].split("```")[0].trim();
    }

    try {
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
