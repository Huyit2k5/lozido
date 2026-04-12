import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'create_invoice_page.dart';

class SelectRoomInvoicePage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const SelectRoomInvoicePage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<SelectRoomInvoicePage> createState() => _SelectRoomInvoicePageState();
}

class _SelectRoomInvoicePageState extends State<SelectRoomInvoicePage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFloor = "Tất cả";
  int _floorCount = 1;

  // Cache to store whether a room has an invoice for the selected month to avoid repeated querying
  Map<String, bool> _invoiceExistsCache = {};
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _floorCount = int.tryParse(widget.houseData['floorCount']?.toString() ?? '1') ?? 1;
    _checkInvoicesForSelectedMonth();
  }

  String get _formattedMonth {
    return "T.${_selectedDate.month}/${_selectedDate.year}";
  }

  Future<void> _checkInvoicesForSelectedMonth() async {
    setState(() {
      _isLoadingCache = true;
      _invoiceExistsCache.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('invoices')
          .where('billingMonth', isEqualTo: DateFormat('MM/yyyy').format(_selectedDate))
          .get();

      final existingInvoices = <String, bool>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['roomId'] != null) {
          existingInvoices[data['roomId']] = true;
        }
      }

      if (mounted) {
        setState(() {
          _invoiceExistsCache = existingInvoices;
          _isLoadingCache = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCache = false;
        });
      }
      debugPrint("Error checking invoices: $e");
    }
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _checkInvoicesForSelectedMonth();
  }

  void _prevMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _checkInvoicesForSelectedMonth();
  }

  void _selectRoom(String roomId, Map<String, dynamic> roomData) {
    if (_invoiceExistsCache[roomId] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cảnh báo'),
          content: Text('Phòng ${roomData['roomName'] ?? "này"} đã có hóa đơn cho $_formattedMonth. Bạn có chắc chắn muốn lập thêm một hóa đơn nữa không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToCreateInvoice(roomId, roomData);
              },
              child: const Text('Tiếp tục đè lên', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      _navigateToCreateInvoice(roomId, roomData);
    }
  }

  void _navigateToCreateInvoice(String roomId, Map<String, dynamic> roomData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoicePage(
          houseId: widget.houseId,
          roomId: roomId,
          roomData: roomData,
          billingMonthDate: _selectedDate,
        ),
      ),
    );

    if (result == true) {
      _checkInvoicesForSelectedMonth(); // Refresh if invoice was created
    }
  }

  String _formatCurrency(double amount) {
    String str = amount.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = str[i] + result;
      count++;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F4F8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: const Text(
          "Chọn 1 để lập hóa đơn",
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Month Picker
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _prevMonth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.chevron_left, size: 24, color: Colors.black87),
                            SizedBox(width: 4),
                            Text("Tháng\ntrước", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Chọn tháng", style: TextStyle(color: Colors.black54, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          "Tháng ${_selectedDate.month}, ${_selectedDate.year}",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: InkWell(
                      onTap: _nextMonth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("Tháng\ntiếp theo", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.2)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 24, color: Colors.black87),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floor Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.settings, size: 20, color: Colors.black87),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00A651),
                              shape: BoxShape.circle,
                            ),
                            child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                  _buildFloorChip("Tất cả"),
                  if (_floorCount > 0) _buildFloorChip("Tầng trệt"),
                  for (int i = 1; i < _floorCount; i++) _buildFloorChip("Tầng $i"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Room List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('houses')
                  .doc(widget.houseId)
                  .collection('rooms')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || _isLoadingCache) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Đã có lỗi xảy ra"));
                }

                var docs = snapshot.data?.docs ?? [];
                
                // Lọc bỏ những phòng Đang trống
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Đang trống';
                  return status != 'Đang trống';
                }).toList();

                if (_selectedFloor != "Tất cả") {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['floor'] == _selectedFloor;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inbox, size: 48, color: Colors.black26),
                        SizedBox(height: 12),
                        Text("Không có phòng đang thuê nào để lập hóa đơn", style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final roomId = docs[index].id;
                    final roomData = docs[index].data() as Map<String, dynamic>;
                    return _buildRoomCard(roomId, roomData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorChip(String label) {
    bool isSelected = _selectedFloor == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFloor = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF81C784) : Colors.white, // green
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF81C784) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(String roomId, Map<String, dynamic> roomData) {
    bool existingInvoice = _invoiceExistsCache[roomId] == true;

    final name = roomData['roomName'] ?? 'Phòng';
    final tenantName = roomData['tenantName'] ?? 'Chưa xác định';
    final tenantPhone = roomData['tenantPhone'] ?? 'Chưa có số';
    final rentPrice = _formatCurrency((roomData['rentPrice'] as num?)?.toDouble() ?? (roomData['price'] as num?)?.toDouble() ?? 0);
    final contractStart = roomData['contractStartDate'] ?? '--/--/----';
    final useApp = roomData['useApp'] == true;
    final isSigned = roomData['contractSigned'] == true;
    final totalMembers = roomData['totalMembers'] ?? 1;

    return GestureDetector(
      onTap: () => _selectRoom(roomId, roomData),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F9F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: existingInvoice ? Colors.red.shade200 : Colors.green.shade100, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: existingInvoice ? Colors.red : const Color(0xFFF97316),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                            child: const Icon(Icons.storefront_rounded, color: Colors.green, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: Colors.black87),
                                    const SizedBox(width: 4),
                                    Text("$tenantName - $tenantPhone", style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right, color: Colors.blueAccent, size: 22),
                          ),
                        ],
                      ),
                      
                      // Cảnh báo nếu đã lập
                      if (existingInvoice) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.shade100),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.red.shade50,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                              const SizedBox(width: 6),
                              Text("Đã có 1 hóa đơn cho $_formattedMonth", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                      ],
                      
                      // Box Detail
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                             _buildBoxRow(Icons.calendar_today_outlined, "Hạn h.đồng", "$contractStart - Vô thời hạn"), // TODO handle if not Vô thời hạn
                             const Divider(height: 1, color: Color(0xFFF1F1F1)),
                             _buildBoxRow(
                                Icons.phone_android_outlined, 
                                "Sử dụng APP", 
                                useApp ? "Đang sử dụng app" : "Chưa sử dụng app",
                                valueColor: useApp ? Colors.green : Colors.deepOrange,
                                valueIcon: useApp ? Icons.check_circle_outline : Icons.info_outline
                             ),
                             const Divider(height: 1, color: Color(0xFFF1F1F1)),
                             _buildBoxRow(
                                Icons.drive_file_rename_outline, 
                                "Hợp đồng online", 
                                isSigned ? "Đã ký" : "Khách chưa ký",
                                valueColor: isSigned ? Colors.green : Colors.deepOrange,
                                valueIcon: isSigned ? Icons.check : Icons.close
                             ),
                             const Divider(height: 1, color: Color(0xFFF1F1F1)),
                             Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sell_outlined, size: 16, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    const Text("Trạng thái", style: TextStyle(fontSize: 13, color: Colors.black87)),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _buildTag("Đang ở", Colors.green),
                                        const SizedBox(height: 6),
                                        _buildTag("Chưa thu tiền", Colors.deepOrange),
                                      ],
                                    ),
                                  ],
                                ),
                             ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(color: const Color(0xFF00A651), borderRadius: BorderRadius.circular(2)),
                                    child: const Icon(Icons.attach_money, color: Colors.white, size: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text("Giá thuê", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("$rentPrice đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.green, size: 14),
                                  const SizedBox(width: 4),
                                  const Text("Khách ghi nhận", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("1/$totalMembers người", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxRow(IconData icon, String label, String value, {Color? valueColor, IconData? valueIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const Spacer(),
          if (valueIcon != null) ...[
            Icon(valueIcon, size: 14, color: valueColor ?? Colors.black87),
            const SizedBox(width: 4),
          ],
          Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
