import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InvoiceImageExportPage extends StatefulWidget {
  final String houseId;
  final String invoiceId;
  final Map<String, dynamic> invoiceData;

  const InvoiceImageExportPage({
    super.key,
    required this.houseId,
    required this.invoiceId,
    required this.invoiceData,
  });

  @override
  State<InvoiceImageExportPage> createState() => _InvoiceImageExportPageState();
}

class _InvoiceImageExportPageState extends State<InvoiceImageExportPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;
  String _houseName = "Nhà trọ của bạn";

  @override
  void initState() {
    super.initState();
    _fetchHouseName();
  }

  Future<void> _fetchHouseName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _houseName = data['propertyName'] ?? "Nhà trọ";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching house name: $e");
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isProcessing = true);
    try {
      final Uint8List? image = await _screenshotController.capture(pixelRatio: 2.0);
      if (image != null) {
        if (kIsWeb) {
          final xFile = XFile.fromData(image, mimeType: 'image/png', name: 'hoadon_${widget.invoiceId}.png');
          await Share.shareXFiles([xFile],
              text: 'Gửi bạn hóa đơn tháng ${widget.invoiceData['billingMonth']}');
        } else {
          final directory = await getTemporaryDirectory();
          final imagePath = await File('${directory.path}/hoadon_${widget.invoiceId}.png').create();
          await imagePath.writeAsBytes(image);

          await Share.shareXFiles([XFile(imagePath.path)],
              text: 'Gửi bạn hóa đơn tháng ${widget.invoiceData['billingMonth']}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chia sẻ: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveImage() async {
    setState(() => _isProcessing = true);
    try {
      final Uint8List? image = await _screenshotController.capture(pixelRatio: 2.0);
      if (image != null) {
        if (kIsWeb) {
          final xFile = XFile.fromData(image, mimeType: 'image/png', name: 'HoaDon_${widget.invoiceId}.png');
          // triggers download on web
          await xFile.saveTo('HoaDon_${widget.invoiceId}.png'); 
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã tải hình ảnh thành công!')),
            );
          }
        } else {
          final result = await ImageGallerySaver.saveImage(
            image,
            quality: 100,
            name: "HoaDon_${widget.invoiceId}",
          );
          if (mounted) {
            if (result['isSuccess'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu hình ảnh vào Thư viện thành công!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể lưu hình ảnh.')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải xuống: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      appBar: AppBar(
        title: const Text("Hình ảnh hóa đơn",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: _buildInvoiceTemplate(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _saveImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text("Tải xuống",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _shareImage,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator())
                        : const Icon(Icons.share, color: Colors.white, size: 18),
                    label: const Text("Chia sẻ",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInvoiceTemplate() {
    final Map<String, dynamic> d = widget.invoiceData;
    final String roomName = d['roomName'] ?? '';
    final String tenantName = d['tenantName'] ?? '';
    final String phone = d['zaloUid'] ?? '';
    final String billingMonth = d['billingMonth'] ?? '';
    
    final Timestamp? createdAt = d['createdAt'];
    final Timestamp? dueDateTs = d['dueDate'];
    final String reason = d['reason'] ?? '';
    final String status = d['status'] ?? 'Chưa thu';

    final double rentAmount = (d['rentAmount'] ?? 0).toDouble();
    final double grandTotal = (d['grandTotal'] ?? 0).toDouble();
    final double paidAmount = (d['paidAmount'] ?? 0).toDouble();
    final double remaining = grandTotal - paidAmount;
    final List<dynamic> payments = d['payments'] ?? [];
    
    // Services
    final List<dynamic> services = d['services'] ?? [];
    final List<dynamic> adjustments = d['adjustments'] ?? [];

    Color statusColor = status == 'Đã thu xong' ? Colors.green : (status == 'Đang nợ tiền' ? Colors.red : Colors.orange);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Text(roomName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 4),
        Text(_houseName,
            style: const TextStyle(color: Colors.black54, fontSize: 15)),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildTemplateDateBox(
                  "Hóa đơn tháng",
                  billingMonth.isNotEmpty
                      ? "T.${billingMonth.split('/').first}, ${billingMonth.split('/').last}"
                      : ""),
              _buildTemplateDateBox(
                  "Ngày lập h.đơn",
                  createdAt != null
                      ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
                      : ""),
              _buildTemplateDateBox(
                  "Hạn nộp tiền",
                  dueDateTs != null
                      ? DateFormat('dd/MM/yyyy').format(dueDateTs.toDate())
                      : ""),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Kính gửi",
                  style: TextStyle(color: Colors.black87, fontSize: 14)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tenantName.isNotEmpty ? tenantName : "Khách hàng",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (phone.isNotEmpty)
                    Text("SĐT: $phone",
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Lý do thu",
                        style: TextStyle(color: Colors.black87, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(reason,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(status,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        
        // Items Breakdown
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (rentAmount > 0)
                 _buildTemplateBreakdownItem("Tiền thuê phòng", rentAmount, subtitle: "1 tháng, 0 ngày"), // Static for now as demo
              
              ...services.map((s) {
                return _buildTemplateBreakdownItem(
                    s['name'] ?? '', (s['total'] ?? 0).toDouble(),
                    subtitle: "${_formatCurrency(s['price'])} đ/${s['unit']}");
              }),

              ...adjustments.map((a) {
                return _buildTemplateBreakdownItem(
                    a['reason'] ?? 'Phát sinh', (a['amount'] ?? 0).toDouble());
              }),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Đã trả",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                  paidAmount > 0
                      ? "Đã trả ${_formatCurrency(paidAmount)} đ"
                      : "Chưa trả lần nào",
                  style: TextStyle(
                      color: paidAmount > 0 ? Colors.green : Colors.red,
                      fontSize: 13)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EC), // Light pastel orange/peach
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepOrange.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Số lần thanh toán",
                      style: TextStyle(color: Colors.black87, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("${payments.length} lần",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Tổng phải trả",
                      style: TextStyle(color: Colors.black87, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("${_formatCurrency(remaining)} đ",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                const TextSpan(
                    text: "* Chú ý: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        "Vui lòng thanh toán đúng hạn và trước ngày ${dueDateTs != null ? DateFormat('dd/MM/yyyy').format(dueDateTs.toDate()) : ''}"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTemplateDateBox(String title, String value) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            right: title != "Hạn nộp tiền"
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateBreakdownItem(String title, double amount,
      {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 14)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ]
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Thành tiền",
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 4),
              Text("${_formatCurrency(amount)} đ",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }
}
