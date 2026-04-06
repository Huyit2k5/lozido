import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceSelectionPage extends StatefulWidget {
  final String houseId;
  final List<Map<String, dynamic>> initialSelectedServices;

  const ServiceSelectionPage({
    super.key,
    required this.houseId,
    required this.initialSelectedServices,
  });

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceItemModel {
  final String name;
  final double price;
  final String unit;
  final bool isMetered;
  bool isSelected;
  TextEditingController controller;
  String? errorText;

  _ServiceItemModel({
    required this.name,
    required this.price,
    required this.unit,
    this.isMetered = false,
    this.isSelected = false,
    String currentIndex = '',
  }) : controller = TextEditingController(text: currentIndex);

  void dispose() {
    controller.dispose();
  }
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  final List<_ServiceItemModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServicesFromFirestore();
  }

  Future<void> _loadServicesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('services')
          .orderBy('createdAt', descending: false)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['serviceName'] ?? '';
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        final unit = data['unit'] ?? '';
        final isMetered = data['isMetered'] ?? false;

        // Kiểm tra xem dịch vụ này đã được chọn trước đó chưa
        final existingSelected = widget.initialSelectedServices.where(
          (s) => s['name'] == name,
        ).toList();

        if (existingSelected.isNotEmpty) {
          final existing = existingSelected.first;
          _services.add(_ServiceItemModel(
            name: name,
            price: price,
            unit: unit,
            isMetered: isMetered,
            isSelected: true,
            currentIndex: existing['currentIndex']?.toString() ?? '',
          ));
        } else {
          _services.add(_ServiceItemModel(
            name: name,
            price: price,
            unit: unit,
            isMetered: isMetered,
            isSelected: false,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dịch vụ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var svc in _services) {
      svc.dispose();
    }
    super.dispose();
  }

  IconData _getServiceIcon(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('điện')) return Icons.bolt;
    if (lower.contains('nước')) return Icons.water_drop;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi;
    if (lower.contains('rác')) return Icons.delete_outline;
    if (lower.contains('xe') || lower.contains('giữ xe')) return Icons.two_wheeler;
    if (lower.contains('vệ sinh')) return Icons.cleaning_services;
    return Icons.miscellaneous_services;
  }

  void _applyServices() {
    bool hasError = false;
    List<Map<String, dynamic>> finalSelection = [];

    setState(() {
      for (var svc in _services) {
        svc.errorText = null;
        if (svc.isSelected) {
          if (svc.isMetered && svc.controller.text.trim().isEmpty) {
            svc.errorText = 'Chỉ số không được để trống';
            hasError = true;
          } else {
            finalSelection.add({
              'name': svc.name,
              'price': svc.price,
              'unit': svc.unit,
              'currentIndex': svc.isMetered
                  ? (double.tryParse(svc.controller.text.trim()) ?? 0)
                  : 0,
            });
          }
        }
      }
    });

    if (!hasError) {
      Navigator.pop(context, finalSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Sửa dịch vụ sử dụng',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)))
          : _services.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black26),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có dịch vụ nào.\nHãy thêm dịch vụ trong phần Cài đặt dịch vụ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: _services.length,
                        separatorBuilder: (context, index) => Container(height: 8, color: const Color(0xFFEFEFEF)),
                        itemBuilder: (context, index) {
                          final svc = _services[index];
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_getServiceIcon(svc.name), color: Colors.black87, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            svc.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                          ),
                                          Text(
                                            svc.isSelected
                                                ? (svc.isMetered ? 'Tính theo đồng hồ, chỉ số chênh lệch' : 'Đang sử dụng')
                                                : 'Chưa được sử dụng',
                                            style: TextStyle(
                                              color: svc.isSelected ? Colors.black54 : Colors.deepOrange.shade300,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: svc.isSelected,
                                      activeColor: const Color(0xFF00A651),
                                      onChanged: (val) {
                                        setState(() {
                                          svc.isSelected = val ?? false;
                                          if (!svc.isSelected) {
                                            svc.controller.clear();
                                            svc.errorText = null;
                                          }
                                        });
                                      },
                                    )
                                  ],
                                ),

                                // Input Field khi là dịch vụ theo đồng hồ và đang được chọn
                                if (svc.isSelected && svc.isMetered) ...[
                                  const SizedBox(height: 12),
                                  const Text('Chỉ số hiện tại', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: svc.controller,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            errorText: svc.errorText,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {},
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              const Text('Ảnh\nchụp', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontSize: 12)),
                                              Positioned(
                                                top: -6,
                                                right: -6,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.lightBlue,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    '* Chỉ số cũ - số mới chỉ xuất hiện khi lập hóa đơn.',
                                    style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                                  ),
                                ],

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),

                                // Price row
                                Text(
                                  'Giá: ${_formatCurrency(svc.price)} đ/${svc.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Đóng', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _applyServices,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A651),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Áp dụng dịch vụ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
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
}
