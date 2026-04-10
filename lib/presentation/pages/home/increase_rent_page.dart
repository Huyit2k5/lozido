import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RoomItem {
  String? id;
  String name;
  double price;
  bool isSelected;

  RoomItem({
    this.id,
    required this.name,
    required this.price,
    this.isSelected = false,
  });
}

class IncreaseRentPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const IncreaseRentPage({super.key, required this.houseId, required this.houseData});

  @override
  State<IncreaseRentPage> createState() => _IncreaseRentPageState();
}

class _IncreaseRentPageState extends State<IncreaseRentPage> {
  final TextEditingController _priceController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  List<RoomItem> _rooms = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .orderBy('name')
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Có dữ liệu trong DB
        _rooms = snapshot.docs.map((doc) {
          final data = doc.data();
          return RoomItem(
            id: doc.id,
            name: data['name'] ?? 'Phòng',
            price: (data['price'] ?? 0).toDouble(),
          );
        }).toList();
      } else {
        // Chưa có dữ liệu -> Tạo danh sách ảo từ roomCount
        int roomCount = widget.houseData['roomCount'] ?? 0;
        if (roomCount <= 0) roomCount = 5; // Fallback
        
        double defaultPrice = (widget.houseData['price'] ?? 0).toDouble();

        _rooms = List.generate(roomCount, (index) {
          return RoomItem(
            name: "Phòng ${index + 1}",
            price: defaultPrice,
          );
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách phòng: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final selectedRooms = _rooms.where((r) => r.isSelected).toList();
    if (selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 phòng để áp dụng.')),
      );
      return;
    }

    final newPriceStr = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newPriceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá thuê mới hợp lệ.')),
      );
      return;
    }

    final newPrice = double.tryParse(newPriceStr) ?? 0.0;

    setState(() {
      _isSaving = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance.collection('houses').doc(widget.houseId).collection('rooms');

      for (var room in selectedRooms) {
        if (room.id != null) {
          // Update existing room
          batch.update(collectionRef.doc(room.id), {'price': newPrice, 'updatedAt': FieldValue.serverTimestamp()});
        } else {
          // Create new room
          final newDoc = collectionRef.doc(); // Auto generate ID
          batch.set(newDoc, {
            'name': room.name,
            'price': newPrice,
            'status': 'Đang trống',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          room.id = newDoc.id; // Update local state so future saves are updates
        }
        room.price = newPrice;
      }

      // Commit to Firestore
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật giá thuê thành công!'), backgroundColor: Colors.green),
        );
        setState(() {
           // Reset checkboxes after save
           for (var r in _rooms) {
             r.isSelected = false;
           }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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

  void _onPriceChanged(String value) {
    // Format input with dots
    String numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isNotEmpty) {
      final number = int.parse(numericOnly);
      final formatted = NumberFormat('#,###', 'vi_VN').format(number).replaceAll(',', '.');
      _priceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  bool get _isAllSelected => _rooms.isNotEmpty && _rooms.every((r) => r.isSelected);
  int get _selectedCount => _rooms.where((r) => r.isSelected).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tăng giá thuê",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                // Banner thông báo tới khách thuê
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD15B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Thông báo tới khách thuê", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.black87),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Field giá thuê
                        const Text.rich(
                          TextSpan(
                            text: "Giá thuê mới ",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                            ]
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "15.000.000",
                                    hintStyle: TextStyle(color: Colors.black38),
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  onChanged: _onPriceChanged,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text("đ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                              )
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        // Tiêu đề chọn phòng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: "Chọn phòng áp dụng ",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                                    children: [
                                      TextSpan(text: "($_selectedCount đã chọn) ", style: const TextStyle(color: Colors.black87)),
                                      const TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                                    ]
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text("Danh sách phòng muốn áp dụng giá mới", style: TextStyle(color: Colors.black54, fontSize: 13)),
                              ],
                            ),
                            Column(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _isAllSelected,
                                    activeColor: Colors.black87,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        for (var room in _rooms) {
                                          room.isSelected = value ?? false;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text("Chọn tất cả", style: TextStyle(fontSize: 12, color: Colors.black87)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Danh sách phòng
                        ..._rooms.map((room) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: CheckboxListTile(
                              value: room.isSelected,
                              activeColor: Colors.black87,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              onChanged: (bool? value) {
                                setState(() {
                                  room.isSelected = value ?? false;
                                });
                              },
                              title: Text(room.name, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                              subtitle: Text(
                                _currencyFormat.format(room.price),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))
            ]
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651), // Màu xanh lá
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Lưu thay đổi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
