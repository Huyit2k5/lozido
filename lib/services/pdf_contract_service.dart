import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class PdfContractService {
  static final _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  static String _formatCurrency(double amount) {
    return '${_currencyFormat.format(amount)}đ';
  }

  static Future<Uint8List> generateContractPdf({
    required Map<String, dynamic> contractData,
    required String roomName,
    required String ownerName,
  }) async {
    final pdf = pw.Document();

    final pw.Font ttf = await PdfGoogleFonts.robotoRegular();
    final pw.Font ttfBold = await PdfGoogleFonts.robotoBold();
    final pw.Font ttfItalic = await PdfGoogleFonts.robotoItalic();

    final pw.TextStyle textStyle = pw.TextStyle(font: ttf, fontSize: 13, lineSpacing: 3);
    final pw.TextStyle boldStyle = pw.TextStyle(font: ttfBold, fontSize: 13, lineSpacing: 3);
    final pw.TextStyle headerStyle = pw.TextStyle(font: ttfBold, fontSize: 16);

    final tenantName = contractData['tenantName'] ?? '..................';
    final rentPrice = (contractData['rentPrice'] ?? 0).toDouble();
    final deposit = (contractData['depositAmount'] ?? 0).toDouble();
    final startDate = contractData['startDate'] ?? '..................';
    final electricPrice = (contractData['electricityPrice'] ?? 0).toDouble();
    final waterPrice = (contractData['waterPrice'] ?? 0).toDouble();
    final duration = contractData['duration'] ?? '..................';
    final billingDate = contractData['billingDate'] ?? '........';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // HEADING
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: headerStyle),
                  pw.Text('Độc lập - Tự do - Hạnh phúc', style: pw.TextStyle(font: ttfBold, fontSize: 14, decoration: pw.TextDecoration.underline)),
                  pw.SizedBox(height: 20),
                  pw.Text('HỢP ĐỒNG CHO THUÊ PHÒNG TRỌ', style: pw.TextStyle(font: ttfBold, fontSize: 18)),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
            
            // BÊN A
            pw.Text('BÊN A : BÊN CHO THUÊ (PHÒNG TRỌ)', style: boldStyle),
            pw.SizedBox(height: 8),
            pw.Text('Họ và tên: $ownerName', style: textStyle),
            pw.Text('Năm sinh: ..............................', style: textStyle),
            pw.Text('CMND/CCCD: ..............................', style: textStyle),
            pw.Text('Ngày cấp: .............................. Nơi cấp: ..............................', style: textStyle),
            pw.Text('Thường trú: .....................................................................', style: textStyle),
            pw.SizedBox(height: 16),

            // BÊN B
            pw.Text('BÊN B : BÊN THUÊ (PHÒNG TRỌ)', style: boldStyle),
            pw.SizedBox(height: 8),
            pw.Text('Họ và tên: $tenantName', style: textStyle),
            pw.Text('Năm sinh: ..............................', style: textStyle),
            pw.Text('CMND/CCCD: ..............................', style: textStyle),
            pw.Text('Ngày cấp: .............................. Nơi cấp: ..............................', style: textStyle),
            pw.Text('Thường trú: .....................................................................', style: textStyle),
            pw.SizedBox(height: 16),

            pw.Text('Hai bên cùng thỏa thuận và đồng ý với nội dung sau:', style: textStyle),
            pw.SizedBox(height: 10),

            // ĐIỀU 1
            pw.Text('Điều 1:', style: boldStyle),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Bullet(text: 'Bên A đồng ý cho bên B thuê một phòng trọ thuộc hệ thống nhà trọ ($roomName).', style: textStyle),
                  pw.Bullet(text: 'Dịch vụ sử dụng:', style: textStyle),
                  pw.SizedBox(height: 8),
                  // Table
                  pw.Table.fromTextArray(
                    context: context,
                    border: pw.TableBorder.all(),
                    cellStyle: textStyle,
                    headerStyle: boldStyle,
                    data: <List<String>>[
                      ['Tên dịch vụ', 'Giá Tiền'],
                      ['Tiền điện', '${_formatCurrency(electricPrice)}/KWh'],
                      ['Tiền nước', '${_formatCurrency(waterPrice)}/Khối'],
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Bullet(text: 'Tài sản phòng sử dụng theo biên bản bàn giao đính kèm.', style: textStyle),
                  pw.Bullet(text: 'Thời hạn thuê phòng trọ là $duration kể từ ngày $startDate.', style: textStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // ĐIỀU 2
            pw.Text('Điều 2:', style: boldStyle),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Bullet(text: 'Giá tiền thuê phòng trọ là ${_formatCurrency(rentPrice)}/tháng.', style: textStyle),
                  pw.Bullet(text: 'Tiền thuê phòng trọ bên B thanh toán cho bên A từ $billingDate dương lịch hàng tháng.', style: textStyle),
                  pw.Bullet(text: 'Bên B đặt tiền thế chân trước ${_formatCurrency(deposit)} cho bên A. Tiền thế chân sẽ được trả vào ngày cuối cùng kết thúc hợp đồng.', style: textStyle),
                  pw.Bullet(text: 'Bên B ngưng hợp đồng trước thời hạn thì phải chịu mất tiền thế chân.', style: textStyle),
                  pw.Bullet(text: 'Bên A ngưng hợp đồng trước thời hạn thì bồi thường gấp đôi số tiền bên B đã thế chân.', style: textStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            
            // ĐIỀU 3
            pw.Text('Điều 3: Trách nhiệm bên A.', style: boldStyle),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Bullet(text: 'Giao phòng trọ, trang thiết bị trong phòng cho bên B đúng ngày ký.', style: textStyle),
                  pw.Bullet(text: 'Hướng dẫn bên B chấp hành đúng các quy định của địa phương, đăng ký tạm trú.', style: textStyle),
                ]
              )
            ),
            pw.SizedBox(height: 10),

            // ĐIỀU 4
            pw.Text('Điều 4: Trách nhiệm bên B.', style: boldStyle),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Bullet(text: 'Trả tiền thuê phòng trọ hàng tháng đúng hạn theo hợp đồng.', style: textStyle),
                  pw.Bullet(text: 'Sử dụng đúng mục đích thuê nhà. Khi sửa chữa phải được sự đồng ý của bên A.', style: textStyle),
                  pw.Bullet(text: 'Bảo quản cẩn thận đồ đạc trang thiết bị không làm hư hỏng mất mát.', style: textStyle),
                ]
              )
            ),
            pw.SizedBox(height: 10),

            // ĐIỀU 5
            pw.Text('Điều 5: Điều khoản chung.', style: boldStyle),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Bullet(text: 'Bên A và bên B thực hiện đúng các điều khoản ghi trong hợp đồng.', style: textStyle),
                  pw.Bullet(text: 'Trường hợp có tranh chấp hai bên cùng nhau bàn bạc giải quyết.', style: textStyle),
                  pw.Bullet(text: 'Hợp đồng được lập thành 02 bản có giá trị ngang nhau, mỗi bên giữ 01 bản.', style: textStyle),
                ]
              )
            ),
            pw.SizedBox(height: 30),

            // CHỮ KÝ
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('BÊN A', style: boldStyle),
                    pw.Text('Ký và ghi rõ họ tên', style: pw.TextStyle(font: ttfItalic, fontSize: 13)),
                    pw.SizedBox(height: 60),
                    pw.Text(ownerName, style: textStyle),
                  ]
                ),
                pw.Column(
                  children: [
                    pw.Text('BÊN B', style: boldStyle),
                    pw.Text('Ký và ghi rõ họ tên', style: pw.TextStyle(font: ttfItalic, fontSize: 13)),
                    pw.SizedBox(height: 60),
                    pw.Text(tenantName, style: textStyle),
                  ]
                ),
              ]
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
