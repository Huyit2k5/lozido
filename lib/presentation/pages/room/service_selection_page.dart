import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelectedServices;

  const ServiceSelectionPage({
    super.key,
    required this.initialSelectedServices,
  });

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceItemModel {
  final String name;
  final double price;
  final String unit;
  final IconData icon;
  bool isSelected;
  TextEditingController controller;
  String? errorText;

  _ServiceItemModel({
    required this.name,
    required this.price,
    required this.unit,
    required this.icon,
    this.isSelected = false,
    String currentIndex = '',
  }) : controller = TextEditingController(text: currentIndex);
  
  void dispose() {
    controller.dispose();
  }
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  final List<_ServiceItemModel> _services = [];

  // Mock template services
  final List<Map<String, dynamic>> _templateServices = [
    {'name': 'Tiền điện', 'price': 1700.0, 'unit': 'KWh', 'icon': Icons.bolt},
    {'name': 'Tiền nước', 'price': 18000.0, 'unit': 'Khối', 'icon': Icons.water_drop},
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    for (var template in _templateServices) {
      // Check if it's already selected
      final existingSelected = widget.initialSelectedServices.where(
        (s) => s['name'] == template['name']
      ).toList();

      if (existingSelected.isNotEmpty) {
        final data = existingSelected.first;
        _services.add(_ServiceItemModel(
          name: data['name'],
          price: (data['price'] as num).toDouble(),
          unit: data['unit'],
          icon: template['icon'],
          isSelected: true,
          currentIndex: data['currentIndex']?.toString() ?? '',
        ));
      } else {
        _services.add(_ServiceItemModel(
          name: template['name'],
          price: template['price'],
          unit: template['unit'],
          icon: template['icon'],
          isSelected: false,
        ));
      }
    }
  }

  @override
  void dispose() {
    for (var svc in _services) {
      svc.dispose();
    }
    super.dispose();
  }

  void _applyServices() {
    bool hasError = false;
    List<Map<String, dynamic>> finalSelection = [];

    setState(() {
      for (var svc in _services) {
        svc.errorText = null;
        if (svc.isSelected) {
          if (svc.controller.text.trim().isEmpty) {
            svc.errorText = 'Chỉ số không được để trống';
            hasError = true;
          } else {
            finalSelection.add({
              'name': svc.name,
              'price': svc.price,
              'unit': svc.unit,
              'currentIndex': double.tryParse(svc.controller.text.trim()) ?? 0,
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
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.blue),
            label: const Text('Cài đặt', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Column(
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
                            child: Icon(svc.icon, color: Colors.black87, size: 24),
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
                                  svc.isSelected ? 'Tính theo đồng hồ, chỉ số chênh lệch' : 'Chưa được sử dụng',
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
                      
                      // Input Field when selected
                      if (svc.isSelected) ...[
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
