import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../services/gemini_service.dart';

class CreateInvoicePage extends StatefulWidget {
  final String houseId;
  final String roomId;
  final Map<String, dynamic> roomData;
  final DateTime billingMonthDate;
  final String? initialReason;
  final DateTime? initialRentFromDate;
  final DateTime? initialRentToDate;
  final bool calculateRentByDays;

  const CreateInvoicePage({
    super.key,
    required this.houseId,
    required this.roomId,
    required this.roomData,
    required this.billingMonthDate,
    this.initialReason,
    this.initialRentFromDate,
    this.initialRentToDate,
    this.calculateRentByDays = false,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class InvoiceAdjustment {
  String reason = '';
  double amount = 0;
  TextEditingController reasonController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  void dispose() {
    reasonController.dispose();
    amountController.dispose();
  }
}

class InvoiceServiceItem {
  final String name;
  final double price;
  final String unit;
  double quantity; // either 1, or (newIndex - oldIndex)
  
  // For metered services
  bool isMetered;
  double oldIndex;
  double newIndex;
  bool isUsed; // Thêm trường đánh dấu xem khách có dùng không

  TextEditingController oldIndexController = TextEditingController();
  TextEditingController newIndexController = TextEditingController();
  TextEditingController quantityController = TextEditingController(); // for flat fee but variable qty

  InvoiceServiceItem({
    required this.name,
    required this.price,
    required this.unit,
    this.isMetered = false,
    this.oldIndex = 0,
    this.newIndex = 0,
    this.quantity = 1,
    this.isUsed = false,
  }) {
    oldIndexController.text = oldIndex.toString();
    newIndexController.text = newIndex.toString();
    quantityController.text = quantity.toString();
  }

  double get total {
    if (!isUsed) return 0;
    return isMetered ? (newIndex - oldIndex > 0 ? (newIndex - oldIndex) * price : 0) : quantity * price;
  }

  void dispose() {
    oldIndexController.dispose();
    newIndexController.dispose();
    quantityController.dispose();
  }
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  String _selectedReason = "Thu tiền phòng theo chu kỳ";
  DateTime _dueDate = DateTime.now().add(const Duration(days: 5));

  // Rent Section
  DateTime _rentFromDate = DateTime.now();
  DateTime _rentToDate = DateTime.now().add(const Duration(days: 30));
  double _rentPrice = 0;
  
  // Deposit
  final _depositController = TextEditingController();

  // Services
  List<InvoiceServiceItem> _serviceItems = [];

  // Adjustments
  List<InvoiceAdjustment> _adjustments = [];

  // Checkbox
  bool _sendZaloApp = true;

  bool _isSaving = false;

  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _recognizedText = "";
  bool _isAnalyzingAI = false;
  Timer? _silenceTimer;
  final TextEditingController _voiceTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _selectedReason = widget.initialReason ?? "Thu tiền phòng theo chu kỳ";
    _rentFromDate = widget.initialRentFromDate ?? DateTime.now();
    _rentToDate = widget.initialRentToDate ?? DateTime.now().add(const Duration(days: 30));
    _rentPrice = (widget.roomData['rentPrice'] as num?)?.toDouble() ?? (widget.roomData['price'] as num?)?.toDouble() ?? 0;

    // If there is an existing 'currentIndex' on service array from roomData, use it as oldIndex
    final List<dynamic> roomServices = widget.roomData['services'] ?? [];
    for (var svc in roomServices) {
      if (svc is Map<String, dynamic>) {
        final name = svc['name'] ?? '';
        final price = (svc['price'] as num?)?.toDouble() ?? 0;
        final unit = svc['unit'] ?? '';
        final oldIdx = (svc['currentIndex'] as num?)?.toDouble() ?? 0;
        
        // Cải thiện nhận diện dịch vụ có chỉ số (điện/nước)
        final unitLower = unit.toLowerCase();
        bool isMetered = unitLower.contains('kwh') || 
                         unitLower.contains('khối') || 
                         unitLower.contains('m3') || 
                         unitLower.contains('m³') || 
                         unitLower.contains('số') || 
                         unitLower.contains('điện') || 
                         unitLower.contains('nước');

        _serviceItems.add(InvoiceServiceItem(
          name: name,
          price: price,
          unit: unit,
          isMetered: isMetered,
          oldIndex: oldIdx,
          newIndex: isMetered ? oldIdx : 0, 
          isUsed: true, // Tự động chọn sử dụng cho tất cả dịch vụ của phòng
        ));
      }
    }
    
    // Listen to changes to real-time update total
    for (var item in _serviceItems) {
      if (item.isMetered) {
        item.oldIndexController.addListener(() {
          setState(() {
            item.oldIndex = double.tryParse(item.oldIndexController.text) ?? 0;
          });
        });
        item.newIndexController.addListener(() {
          setState(() {
            item.newIndex = double.tryParse(item.newIndexController.text) ?? 0;
          });
        });
      } else {
         item.quantityController.addListener(() {
          setState(() {
            item.quantity = double.tryParse(item.quantityController.text) ?? 0;
          });
        });
      }
    }

    _depositController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _voiceTextController.dispose();
    _depositController.dispose();
    for (var item in _serviceItems) {
      item.dispose();
    }
    for (var item in _adjustments) {
      item.dispose();
    }
    super.dispose();
  }

  double get _totalRent {
    if (widget.calculateRentByDays || _selectedReason == 'Thu tiền khi kết thúc hợp đồng') {
      int days = _rentToDate.difference(_rentFromDate).inDays;
      if (days < 0) days = 0;
      return (_rentPrice / 30) * days;
    }
    return _rentPrice;
  }

  double get _totalDeposit => double.tryParse(_depositController.text.replaceAll('.', '')) ?? 0;
  double get _totalServices => _serviceItems.fold(0, (sum, item) => sum + item.total);
  double get _totalAdjustments => _adjustments.fold(0, (sum, item) => sum + item.amount);

  double get _grandTotal => _totalRent + _totalDeposit + _totalServices + _totalAdjustments;

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (val) {
          if (!mounted) return;
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('onError: $val');
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (available && mounted) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) {
            if (!mounted) return;
            setState(() {
              _recognizedText = val.recognizedWords;
              _voiceTextController.text = _recognizedText;
            });
            
            // Tự động tắt mic sau 3s không nói
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 3), () {
              if (mounted && _isListening) {
                _speechToText.stop();
                setState(() => _isListening = false);
                if (_voiceTextController.text.isNotEmpty) {
                  _analyzeAI(_voiceTextController.text);
                }
              }
            });
          },
          localeId: 'vi_VN', // Cố định nhận diện tiếng Việt
          pauseFor: const Duration(seconds: 3),
        );
      }
    } else {
      _silenceTimer?.cancel();
      if (mounted) setState(() => _isListening = false);
      _speechToText.stop();
      if (_voiceTextController.text.isNotEmpty) {
        _analyzeAI(_voiceTextController.text);
      }
    }
  }

  Future<void> _analyzeAI(String text) async {
    if (text.trim().isEmpty) return;
    if (_isAnalyzingAI) return;
    if (!mounted) return;
    setState(() {
      _isAnalyzingAI = true;
    });
    try {
      final List<Map<String, dynamic>> data = await GeminiService().parseInvoiceAdjustments(text);
      
      if (!mounted) return;
      setState(() {
        for (var item in data) {
          final adj = InvoiceAdjustment();
          adj.reasonController.text = item['reason'];
          adj.reason = item['reason'];
          double amt = (item['price'] as num).toDouble();
          adj.amountController.text = amt.toStringAsFixed(0);
          adj.amount = amt;
          
          adj.amountController.addListener(() {
            if (!mounted) return;
            setState(() {
              String val = adj.amountController.text.replaceAll('.', '').replaceAll(',', '');
              adj.amount = double.tryParse(val) ?? 0;
            });
          });
          adj.reasonController.addListener(() {
            adj.reason = adj.reasonController.text;
          });
          
          _adjustments.add(adj);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phân tích và thêm thành công!'), backgroundColor: Colors.green),
        );
        _voiceTextController.clear();
        _recognizedText = "";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phân tích AI: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingAI = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0';
    String str = amount.abs().toStringAsFixed(0);
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
    return (amount < 0 ? "-" : "") + result;
  }

  String _getRentDurationText() {
    if (widget.calculateRentByDays || _selectedReason == 'Thu tiền khi kết thúc hợp đồng') {
      int days = _rentToDate.difference(_rentFromDate).inDays;
      if (days < 0) days = 0;
      return "$days ngày";
    }
    return "1 tháng, 0 ngày";
  }

  void _addAdjustment() {
    setState(() {
      final adj = InvoiceAdjustment();
      adj.amountController.addListener(() {
        setState(() {
          String val = adj.amountController.text.replaceAll('.', '').replaceAll(',', '');
          adj.amount = double.tryParse(val) ?? 0;
        });
      });
      adj.reasonController.addListener(() {
        adj.reason = adj.reasonController.text;
      });
      _adjustments.add(adj);
    });
  }

  void _removeAdjustment(int index) {
    setState(() {
      _adjustments[index].dispose();
      _adjustments.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _rentFromDate : _rentToDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00A651)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _rentFromDate = picked;
        } else {
          _rentToDate = picked;
        }
      });
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00A651)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveInvoice() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final invoiceData = {
        'roomId': widget.roomId,
        'roomName': widget.roomData['roomName'],
        'tenantName': widget.roomData['tenantName'] ?? "Khách hàng",
        'zaloUid': widget.roomData['tenantPhone'], // Dùng số điện thoại làm UID như yêu cầu
        'billingMonth': DateFormat('MM/yyyy').format(widget.billingMonthDate),
        'reason': _selectedReason,
        'dueDate': _dueDate,
        'rentStart': _rentFromDate,
        'rentEnd': _rentToDate,
        'rentAmount': _totalRent,
        'depositAmount': _totalDeposit,
        'services': _serviceItems.map((s) => {
          'name': s.name,
          'price': s.price,
          'unit': s.unit,
          'isMetered': s.isMetered,
          'oldIndex': s.oldIndex,
          'newIndex': s.newIndex,
          'quantity': s.quantity,
          'total': s.total,
        }).toList(),
        'adjustments': _adjustments.map((a) => {
          'reason': a.reason,
          'amount': a.amount,
        }).toList(),
        'grandTotal': _grandTotal,
        'sendZaloApp': _sendZaloApp,
        'status': 'Chưa thu',
        'paidAmount': 0,
        'payments': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Ensure 'invoices' subcollection exists conceptually by just adding
      final docRef = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('invoices')
          .add(invoiceData);

      // Also updates the room's services 'currentIndex' tracking if metered
      if (_serviceItems.isNotEmpty) {
        final List<dynamic> oldServices = widget.roomData['services'] ?? [];
        List<Map<String, dynamic>> updatedServices = [];
        for (var oldSvc in oldServices) {
          if (oldSvc is Map<String, dynamic>) {
            // Find if we have new index
            var invoiceSvc = _serviceItems.where((s) => s.name == oldSvc['name']).firstOrNull;
            if (invoiceSvc != null && invoiceSvc.isMetered) {
              updatedServices.add({
                ...oldSvc,
                'currentIndex': invoiceSvc.newIndex,
              });
            } else {
              updatedServices.add(Map<String, dynamic>.from(oldSvc));
            }
          }
        }
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('rooms')
            .doc(widget.roomId)
            .update({'services': updatedServices});
      }

      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A651),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  "Hóa đơn T.${widget.billingMonthDate.month}/${widget.billingMonthDate.year} đã được thêm thành công!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF00A651), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    children: [
                      const TextSpan(text: "Số tiền cần thu là: "),
                      TextSpan(text: "${_formatCurrency(_grandTotal)}đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_sendZaloApp) ...[
                  // Warning if decided not to send
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.deepOrange, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text("Giá trị hóa đơn đã được lưu nhưng không thông báo qua Zalo/App.", style: TextStyle(color: Colors.deepOrange, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close sheet
                      Navigator.pop(context, true); // back to SelectRoom (sends true to refresh)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Đóng", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReasonModalPicker() {
    final reasons = [
      {'title': 'Thu tiền khi kết thúc hợp đồng', 'desc': 'Chỉ áp dụng khi khách muốn chấm dứt hợp đồng', 'icon': Icons.logout},
      {'title': 'Thu tiền phòng theo chu kỳ', 'desc': 'Chỉ áp dụng khi thu tiền thuê 1 tháng hoặc chu kỳ thuê nhiều tháng', 'icon': Icons.home},
      {'title': 'Thu tiền dịch vụ', 'desc': 'Chỉ áp dụng khi chỉ muốn thu tiền dịch vụ khách sử dụng', 'icon': Icons.room_service},
      {'title': 'Thu tiền cọc', 'desc': 'Chỉ áp dụng khi khách đóng tiền cọc chính thức thuê', 'icon': Icons.monetization_on},
      {'title': 'Hoàn tiền cọc', 'desc': 'Chỉ áp dụng khi khách thuê trả phòng và hoàn cọc ban đầu', 'icon': Icons.keyboard_return},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.list, color: Colors.black87),
                    const SizedBox(width: 8),
                    const Text("Lý do lập hóa đơn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                flex: 0,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: reasons.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (context, index) {
                    final item = reasons[index];
                    return ListTile(
                      leading: Icon(item['icon'] as IconData, color: Colors.black87),
                      title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(item['desc'] as String, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      onTap: () {
                        setState(() {
                          _selectedReason = item['title'] as String;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Đóng", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showServiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.room_service_outlined, color: Colors.black87),
                          const SizedBox(width: 8),
                          const Text("Chốt dịch vụ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: _serviceItems.map((svc) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(svc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                            const SizedBox(height: 4),
                                            Text("${_formatCurrency(svc.price)} đ/${svc.unit}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: svc.isUsed,
                                                  activeColor: const Color(0xFF00A651),
                                                  onChanged: (val) {
                                                    setModalState(() {
                                                      svc.isUsed = val ?? false;
                                                    });
                                                    setState(() {});
                                                  },
                                                ),
                                                const Text("Có sử dụng", style: TextStyle(fontSize: 13))
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      if (svc.isUsed && svc.isMetered) ...[
                                        // Metered: Số cũ, Số mới
                                        Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(right: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Số cũ", style: TextStyle(fontSize: 12, color: Colors.black54)),
                                              const SizedBox(height: 4),
                                              TextField(
                                                controller: svc.oldIndexController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onChanged: (_) {
                                                  setModalState((){});
                                                  setState((){});
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(right: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Số mới", style: TextStyle(fontSize: 12, color: Colors.black54)),
                                              const SizedBox(height: 4),
                                              TextField(
                                                controller: svc.newIndexController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orange)),
                                                ),
                                                onChanged: (_) {
                                                  setModalState((){});
                                                  setState((){});
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else if (svc.isUsed && !svc.isMetered) ...[
                                        // Variable Qty for flat service
                                        Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(right: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Số lượng (${svc.unit})", style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1),
                                              const SizedBox(height: 4),
                                              TextField(
                                                controller: svc.quantityController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onChanged: (_) {
                                                  setModalState((){});
                                                  setState((){});
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text("Thành tiền: ", style: TextStyle(color: Colors.grey.shade600)),
                                      Text("${_formatCurrency(svc.total)} đ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Divider(),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A651),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Xác nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lập hóa đơn", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
            Text("Tháng [ T.${widget.billingMonthDate.month}/${widget.billingMonthDate.year} ]", style: const TextStyle(color: Color(0xFF00A651), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // --- Thông tin căn bản hóa đơn ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.login_outlined, color: Colors.black87),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      text: "Lý do lập hóa đơn ",
                                      style: TextStyle(color: Colors.black54, fontSize: 12),
                                      children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _showReasonModalPicker,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedReason,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFEEEEEE)),
                        InkWell(
                          onTap: () => _selectDueDate(context),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      text: "Hạn đóng tiền ",
                                      style: TextStyle(color: Colors.black54, fontSize: 12),
                                      children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_dueDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.calendar_month, color: Colors.black54, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Tiền Phòng ---
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildSectionHeader(Icons.tag, "Thu tiền phòng", "Dựa theo ngày thuê để tính tiền"),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: const TextSpan(
                                            text: "Từ ngày ",
                                            style: TextStyle(color: Colors.black54, fontSize: 12),
                                            children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(DateFormat('dd/MM/yyyy').format(_rentFromDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: const TextSpan(
                                            text: "Đến ngày ",
                                            style: TextStyle(color: Colors.black54, fontSize: 12),
                                            children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(DateFormat('dd/MM/yyyy').format(_rentToDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getRentDurationText(), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text("x ${_formatCurrency(_rentPrice)} đ / tháng", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Thành tiền", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text("${_formatCurrency(_totalRent)} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Tiền Cọc ---
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildSectionHeader(Icons.tag, "Thu tiền cọc", "Thu tiền cọc nếu có phát sinh"),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: TextField(
                            controller: _depositController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: "Nhập số tiền cọc (nếu có)",
                              suffixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.tag, size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text("Chọn mẫu", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Số tiền cọc cần thu", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text("${_formatCurrency(_totalDeposit)} đ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Thành tiền", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text("${_formatCurrency(_totalDeposit)} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --- Dịch vụ tính tiền ---
                  if (_serviceItems.isNotEmpty)
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSectionHeader(Icons.tag, "Dịch vụ tính tiền", "Chốt mức khách sử dụng để tính tiền", iconBgColor: const Color(0xFF00A651)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _serviceItems.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                    itemBuilder: (context, index) {
                                      final svc = _serviceItems[index];

                                      return Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(svc.name, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                  const SizedBox(height: 2),
                                                  Text("${_formatCurrency(svc.price)} đ/1 ${svc.unit}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (!svc.isUsed) ...[
                                                    const Text("Số: Không sử dụng", style: TextStyle(fontSize: 12, color: Colors.black87)),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                                                          const SizedBox(width: 4),
                                                          const Text("Không sử dụng", style: TextStyle(fontSize: 11, color: Colors.black54)),
                                                        ],
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    if (svc.isMetered) ...[
                                                      Text("Cũ: ${svc.oldIndex} - Mới: ${svc.newIndex}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                                            const SizedBox(width: 4),
                                                            Text("Dùng: ${svc.newIndex - svc.oldIndex} ${svc.unit}", style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                    ] else ...[
                                                      const Text("Loại: Cố định", style: TextStyle(fontSize: 12, color: Colors.black87)),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                                            const SizedBox(width: 4),
                                                            Text("SL: ${svc.quantity}", style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                    ]
                                                  ]
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                              child: const Text("Không\nảnh", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                  InkWell(
                                    onTap: _showServiceModal,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      color: Colors.grey.shade100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.edit, size: 16, color: Colors.black87),
                                          SizedBox(width: 8),
                                          Text("Chốt dịch vụ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4FAEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Tính tiền dịch vụ", style: TextStyle(color: Colors.black87, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: const TextSpan(
                                          style: TextStyle(color: Colors.black87, fontSize: 13),
                                          children: [
                                            TextSpan(text: "1 ", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                            TextSpan(text: "tháng, "),
                                            TextSpan(text: "0 ", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                            TextSpan(text: "ngày"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text("Thành tiền", style: TextStyle(color: Colors.black87, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text("${_formatCurrency(_totalServices)} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 8),

                  // --- Giảm trừ / Cổng thêm ---
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.tag, "Phát sinh khác (Giảm trừ/Cộng thêm)", "Ví dụ: Lì xì -200000, Thay bóng đèn 50000"),
                        
                        // UI Nhập liệu giọng nói AI
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _voiceTextController,
                            decoration: InputDecoration(
                              hintText: "Nói vào đây (VD: Phí vệ sinh 50k...)",
                              labelText: "Nói vào đây",
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isAnalyzingAI)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none, 
                                      color: _isListening ? Colors.red : Colors.blueGrey
                                    ),
                                    onPressed: _listen,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.auto_awesome, color: Colors.black87),
                                    onPressed: () {
                                      _silenceTimer?.cancel();
                                      if (_isListening) {
                                        _speechToText.stop();
                                        setState(() => _isListening = false);
                                      }
                                      _analyzeAI(_voiceTextController.text);
                                    },
                                    tooltip: "Phân tích",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _adjustments.length,
                          itemBuilder: (context, index) {
                            final adj = _adjustments[index];
                            return Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: adj.reasonController,
                                      decoration: InputDecoration(
                                        hintText: "Lý do (VD: Cắt cỏ)",
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: adj.amountController,
                                      keyboardType: TextInputType.numberWithOptions(signed: true),
                                      decoration: InputDecoration(
                                        hintText: "-100k / 100k",
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.blueGrey),
                                    onPressed: () => _removeAdjustment(index),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: InkWell(
                            onTap: _addAdjustment,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "+ Thêm mục cộng thêm / giảm trừ",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _sendZaloApp,
                        activeColor: const Color(0xFF00A651),
                        onChanged: (val) {
                          setState(() {
                            _sendZaloApp = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Gửi ZALO & APP khách thuê", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("Tự động gửi ZALO & APP khách thuê", style: TextStyle(color: Colors.black54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Tổng cộng", style: TextStyle(color: Colors.black54, fontSize: 12)),
                        Text("${_formatCurrency(_grandTotal)} đ", style: const TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveInvoice,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.post_add, color: Colors.white),
                    label: Text(_isSaving ? "Đang xử lý..." : "Lập hóa đơn", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildSectionHeader(IconData icon, String title, String subtitle, {Color iconBgColor = const Color(0xFF00A651)}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.rectangle, borderRadius: const BorderRadius.all(Radius.circular(4))),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}