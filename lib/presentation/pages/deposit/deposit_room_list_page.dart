import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'deposit_page.dart';

class DepositRoomListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const DepositRoomListPage({super.key, required this.houseId, required this.houseData});

  @override
  State<DepositRoomListPage> createState() => _DepositRoomListPageState();
}

class _DepositRoomListPageState extends State<DepositRoomListPage> {
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';

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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Có thể \"Cọc giữ chỗ\"", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Chọn 1 phòng để thực hiện", style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('rooms')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Không thể tải danh sách phòng"));
          }

          final allDocs = snapshot.data?.docs ?? [];
          
          // Filter to only 'Đang trống' and 'Đang cọc giữ chỗ', excluding 'Đã thuê'
          final relevantDocs = allDocs.where((doc) {
            final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'Đang trống';
            return status == 'Đang trống' || status == 'Đang cọc giữ chỗ';
          }).toList();

          int countTatCa = relevantDocs.length;
          int countDangCoc = relevantDocs.where((d) => ((d.data() as Map<String, dynamic>)['status'] ?? '') == 'Đang cọc giữ chỗ').length;

          // Apply selected filter
          var filteredDocs = relevantDocs;
          if (_selectedFilter == 'Đang cọc giữ chỗ') {
            filteredDocs = relevantDocs.where((d) => ((d.data() as Map<String, dynamic>)['status'] ?? '') == 'Đang cọc giữ chỗ').toList();
          }

          // Apply search
          if (_searchQuery.isNotEmpty) {
            filteredDocs = filteredDocs.where((d) {
              final name = ((d.data() as Map<String, dynamic>)['roomName'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return Column(
            children: [
              Container(
                color: const Color(0xFFF0F2F5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tên phòng...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter Chips
                    Row(
                      children: [
                        _buildFilterChip('Tất cả', countTatCa, Icons.filter_alt_outlined),
                        const SizedBox(width: 12),
                        _buildFilterChip('Đang cọc giữ chỗ', countDangCoc, null),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredDocs.isEmpty 
                  ? const Center(child: Text("Không tìm thấy phòng phù hợp."))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        return _buildDepositRoomCard(doc.id, doc.data() as Map<String, dynamic>);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, IconData? icon) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00A651).withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: isSelected ? const Color(0xFF00A651) : Colors.black87),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF00A651) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDepositRoomCard(String roomId, Map<String, dynamic> roomData) {
    final name = roomData['roomName'] ?? 'Phòng';
    final priceInfo = _formatCurrency((roomData['price'] as num?)?.toDouble() ?? 0);
    final status = roomData['status'] ?? 'Đang trống';
    final bool isReserved = status == 'Đang cọc giữ chỗ';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
             builder: (context) => DepositPage(
               houseId: widget.houseId, 
               roomId: roomId, 
               roomData: roomData,
               isViewMode: isReserved,
             ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.blueAccent),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Status Section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sell_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 8),
                            const Text("Trạng thái", style: TextStyle(color: Colors.black87, fontSize: 13)),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildStatusTag(status, isReserved ? Colors.deepOrange : Colors.deepOrange),
                                const SizedBox(height: 4),
                                _buildStatusTag("Chờ kỳ thu tới", Colors.green),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00A651),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.attach_money, color: Colors.white, size: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text("Giá thuê", style: TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("$priceInfo đ", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                            ],
                          ),
                          if (isReserved)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A651),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.attach_money, color: Colors.white, size: 10),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text("Tiền cọc giữ chỗ", style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // We fetch depositAmount from roomData if available, else show '--'
                                // We will format it if we have it in roomData. Otherwise 0.
                                Text(
                                  "${_formatCurrency((roomData['depositAmount'] as num?)?.toDouble() ?? 0)} đ", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepOrange)
                                ),
                              ],
                            )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}
