import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../invoice/create_invoice_page.dart';

class TerminateContractPage extends StatefulWidget {
  final String houseId;
  final String roomId;
  final Map<String, dynamic> houseData;
  final Map<String, dynamic> roomData;

  const TerminateContractPage({
    Key? key,
    required this.houseId,
    required this.roomId,
    required this.houseData,
    required this.roomData,
  }) : super(key: key);

  @override
  State<TerminateContractPage> createState() => _TerminateContractPageState();
}

class _TerminateContractPageState extends State<TerminateContractPage> {
  DateTime _leaveDate = DateTime.now();
  bool _isInvoiceDone = false;
  bool _isAssetChecked = false;
  
  bool _isLoading = true;
  String? _contractId;
  Map<String, dynamic>? _contractData;

  @override
  void initState() {
    super.initState();
    _fetchContractData();
  }

  Future<void> _fetchContractData() async {
    try {
      final activeContracts = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .where('roomId', isEqualTo: widget.roomId)
          .where('status', isEqualTo: 'Active')
          .get();

      if (activeContracts.docs.isNotEmpty) {
        setState(() {
          _contractId = activeContracts.docs.first.id;
          _contractData = activeContracts.docs.first.data();
        });
      }
    } catch (e) {
      debugPrint("Error fetching contract: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leaveDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A651), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _leaveDate) {
      setState(() {
        _leaveDate = picked;
      });
    }
  }

  Future<void> _submitTermination() async {
    if (!_isInvoiceDone || !_isAssetChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng hoàn thành các công việc trước khi kết thúc hợp đồng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00A651)),
        ),
      );

      // --- KEEPING EXISTING FIREBASE LOGIC EXACTLY AS REQUESTED ---
      final activeContracts = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .where('roomId', isEqualTo: widget.roomId)
          .where('status', isEqualTo: 'Active')
          .get();

      if (activeContracts.docs.isNotEmpty) {
        final docId = activeContracts.docs.first.id;
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .doc(docId)
            .update({'status': 'Đã kết thúc', 'endedAt': FieldValue.serverTimestamp()});
      }

      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .doc(widget.roomId)
          .update({'status': 'Đang trống'});
      // -------------------------------------------------------------

      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kết thúc hợp đồng thành công!')),
        );
        Navigator.pop(context); // return to previous page
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  int get completedTasksCount {
    int count = 0;
    if (_isInvoiceDone) count++;
    if (_isAssetChecked) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00A651))),
      );
    }

    final roomName = widget.roomData['roomName'] ?? 'Phòng';
    final houseName = widget.houseData['name'] ?? 'Nhà trọ';
    final displayId = _contractId != null 
      ? (_contractId!.length > 15 ? "${_contractId!.substring(0, 15)}..." : _contractId!)
      : "Không tìm thấy";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Kết thúc hợp đồng",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP INFO SECTION ---
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kết thúc hợp đồng cho $roomName",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          houseName,
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        
                        // ID block
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayId,
                                  style: const TextStyle(
                                    color: Color(0xFF00A651), 
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // Sao chép button
                              InkWell(
                                onTap: () {
                                  if (_contractId != null) {
                                    Clipboard.setData(ClipboardData(text: _contractId!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã sao chép mã hợp đồng'))
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.copy, size: 14, color: Colors.black87),
                                      SizedBox(width: 4),
                                      Text("Sao chép", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Chia sẻ button
                              InkWell(
                                onTap: () {
                                  // Share logic ignored for now
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.share, size: 14, color: Colors.black87),
                                      SizedBox(width: 4),
                                      Text("Chia sẻ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Status pills
                        Row(
                          children: [
                            _buildStatusPill("Đang ở"),
                            const SizedBox(width: 8),
                            _buildStatusPill("Chờ kỳ thu tới"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --- DATE SELECTION SECTION ---
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A651),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("#", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text("Ngày kết thúc hợp đồng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  SizedBox(height: 2),
                                  Text("Là ngày thực tế khách thuê muốn rời đi", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: const TextSpan(
                                          text: 'Ngày khách rời đi ',
                                          style: TextStyle(color: Colors.black54, fontSize: 12),
                                          children: [
                                            TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                                          ]
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_leaveDate),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.black54),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --- CHECKLIST SECTION ---
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A651),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("#", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text("Việc cần làm trước khi kết thúc hợp đồng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  SizedBox(height: 2),
                                  Text("Bạn phải hoàn thành một số việc bên dưới trước khi khách rời đi", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$completedTasksCount/2",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("việc đã làm xong!", style: TextStyle(color: Colors.black87, fontSize: 14)),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Task 1: Hóa đơn
                        _buildTaskCard(
                          isDone: _isInvoiceDone,
                          title: "Lập hóa đơn tháng cuối",
                          subtitle: "Không bắt buộc phải làm!",
                          subtitleColor: Colors.deepOrange,
                          description: "Hệ thống phát hiện bạn chưa tạo hóa đơn tháng cuối. Vui lòng tạo và thu hóa đơn tháng cuối trước khi kết thúc hợp đồng",
                          actionWidget: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() { _isInvoiceDone = true; });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text("Bỏ qua", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateInvoicePage(
                                          houseId: widget.houseId,
                                          roomId: widget.roomId,
                                          roomData: widget.roomData,
                                          billingMonthDate: DateTime.now(),
                                          initialReason: 'Thu tiền khi kết thúc hợp đồng',
                                          initialRentFromDate: DateTime.now(),
                                          initialRentToDate: _leaveDate,
                                          calculateRentByDays: true,
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        setState(() { _isInvoiceDone = true; });
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4FAEE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text("Tạo hóa đơn tháng cuối", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A651))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Task 2: Tài sản
                        _buildTaskCard(
                          isDone: _isAssetChecked,
                          title: "Kiểm tra tài sản",
                          subtitle: "Không bắt buộc phải làm!",
                          subtitleColor: Colors.deepOrange,
                          description: "Kiểm tra lại tài sản, thiết bị trong trước khi kết thúc hợp đồng",
                          actionWidget: InkWell(
                            onTap: () {
                              setState(() { _isAssetChecked = true; });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4FAEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text("Đã kiểm tra tài sản", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A651))),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // --- BOTTOM ACTION NAVIGATION ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                )
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _submitTermination,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A651),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text("Kết thúc hợp đồng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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

  Widget _buildStatusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            decoration: const BoxDecoration(
              color: Color(0xFF8BC34A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required bool isDone,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required String description,
    required Widget actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFF4FAEE) : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.close,
                  color: isDone ? const Color(0xFF00A651) : Colors.deepOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isDone) 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text("Công việc đã hoàn thành", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            )
          else 
            actionWidget,
        ],
      ),
    );
  }
}
