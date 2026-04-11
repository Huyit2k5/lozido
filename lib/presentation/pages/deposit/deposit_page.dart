import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lozido_app/core/utils/currency_formatter.dart';

class DepositPage extends StatefulWidget {
  final String houseId;
  final String roomId;
  final Map<String, dynamic> roomData;
  final bool isViewMode; // true if 'Đang cọc giữ chỗ', false if 'Đang trống'

  const DepositPage({
    super.key,
    required this.houseId,
    required this.roomId,
    required this.roomData,
    required this.isViewMode,
  });

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _depositDate = DateTime.now();
  DateTime? _moveInDate = DateTime.now();
  final TextEditingController _tenantNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _depositAmountController = TextEditingController();
  String _paymentMethod = 'Tiền mặt';
  String? _activeDepositDocId;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isViewMode) {
      _loadActiveDeposit();
    } else {
      final double price = (widget.roomData['price'] as num?)?.toDouble() ?? 0;
      _depositAmountController.text = NumberFormat.decimalPattern('vi_VN').format(price);
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _phoneController.dispose();
    _depositAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveDeposit() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('deposits')
          .where('roomId', isEqualTo: widget.roomId)
          .where('status', isEqualTo: 'Active')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        _activeDepositDocId = doc.id;
        
        setState(() {
          _tenantNameController.text = data['tenantName'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _paymentMethod = data['paymentMethod'] ?? 'Tiền mặt';
          if (data['depositDate'] != null) {
            _depositDate = (data['depositDate'] as Timestamp).toDate();
          }
          if (data['expectedMoveInDate'] != null) {
            _moveInDate = (data['expectedMoveInDate'] as Timestamp).toDate();
          }

          final double amount = (data['depositAmount'] as num?)?.toDouble() ?? 0;
          _depositAmountController.text = NumberFormat.decimalPattern('vi_VN').format(amount);
        });
      }
    } catch (e) {
      debugPrint("Error loading deposit: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _selectDate(BuildContext context, bool isDepositDate) async {
    if (widget.isViewMode && isDepositDate) return; // Prevent changing start date in view mode

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDepositDate ? (_depositDate ?? DateTime.now()) : (_moveInDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isDepositDate) {
          _depositDate = picked;
        } else {
          _moveInDate = picked;
          if (widget.isViewMode) {
             _extendMoveInDate(); // specifically asked for 'Gia hạn ngày vào' functionality
          }
        }
      });
    }
  }

  Future<void> _extendMoveInDate() async {
    if (_activeDepositDocId == null || _moveInDate == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('deposits')
          .doc(_activeDepositDocId)
          .update({'expectedMoveInDate': Timestamp.fromDate(_moveInDate!)});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gia hạn ngày vào thành công!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Thông báo thành công",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text("Cọc giữ chỗ thành công!", style: TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      Navigator.pop(context); // Go back to list
                    },
                    child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitDeposit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_depositDate == null || _moveInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn đầy đủ ngày!")));
      return;
    }

    try {
      final double depositAmount = double.tryParse(_depositAmountController.text.replaceAll('.', '')) ?? 0;
      
      // Save deposit record
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('deposits')
          .add({
        'roomId': widget.roomId,
        'tenantName': _tenantNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'depositDate': Timestamp.fromDate(_depositDate!),
        'expectedMoveInDate': Timestamp.fromDate(_moveInDate!),
        'depositAmount': depositAmount,
        'paymentMethod': _paymentMethod,
        'status': 'Active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update room status
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'status': 'Đang cọc giữ chỗ',
        'depositAmount': depositAmount, // cache for easy UI display in lists
      });

      _showSuccessModal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  Future<void> _cancelDeposit() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận bỏ cọc"),
        content: const Text("Bạn có chắc chắn muốn bỏ cọc giữ chỗ này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Đóng", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Bỏ cọc", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true && _activeDepositDocId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('deposits')
            .doc(_activeDepositDocId)
            .update({'status': 'Canceled', 'canceledAt': FieldValue.serverTimestamp()});
            
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('rooms')
            .doc(widget.roomId)
            .update({'status': 'Đang trống', 'depositAmount': FieldValue.delete()});

        if (mounted) {
          Navigator.pop(context); // go back
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRent = _formatCurrency((widget.roomData['price'] as num?)?.toDouble() ?? 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isViewMode ? "Thông tin cọc giữ chỗ" : "Đặt cọc giữ chỗ",
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)))
        : Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.numbers, "Thông tin cơ bản", "Ngày cọc, ngày vào ở, thông tin khách cọc"),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildDatePickerField("Ngày cọc giữ chỗ *", _depositDate, () => _selectDate(context, true))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDatePickerField("Ngày dự kiến vào ở *", _moveInDate, () => _selectDate(context, false))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField("Tên người cọc *", _tenantNameController, "Nhập tên người cọc", enabled: !widget.isViewMode),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField("Số điện thoại *", _phoneController, "Số điện thoại", enabled: !widget.isViewMode, keyboardType: TextInputType.phone),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionHeader(Icons.numbers, "Thông tin giá cọc", "Số tiền cọc, số tiền này sẽ chuyển thành cọc chính thức khi thêm hợp đồng"),
                      const SizedBox(height: 16),
                      
                      const Text("Số tiền cọc giữ chỗ *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _depositAmountController,
                        enabled: !widget.isViewMode,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Nhập số tiền",
                          suffixText: "đ",
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // Current Rent Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Giá thuê hiện tại", style: TextStyle(color: Colors.black54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text("$currentRent đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Method
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline, color: Colors.black87),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("P.thức thanh toán", style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _paymentMethod,
                                      isDense: true,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                      items: widget.isViewMode 
                                          ? [DropdownMenuItem(value: _paymentMethod, child: Text(_paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)))]
                                          : ['Tiền mặt', 'Chuyển khoản'].map((String value) {
                                            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)));
                                          }).toList(),
                                      onChanged: widget.isViewMode ? null : (newValue) {
                                        setState(() {
                                          if (newValue != null) _paymentMethod = newValue;
                                        });
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00A651),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('dd/MM/yyyy').format(date) : "Chọn ngày",
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.black87),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool enabled = true, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập' : null,
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: widget.isViewMode ? [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0
              ),
              icon: const Icon(Icons.close, size: 18),
              label: const Text("Bỏ cọc giữ chỗ", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _cancelDeposit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Gia hạn ngày vào", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _selectDate(context, false),
            ),
          )
        ] : [
          Expanded(
            flex: 1,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Thêm cọc giữ chỗ", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _submitDeposit,
            ),
          )
        ],
      ),
    );
  }
}
