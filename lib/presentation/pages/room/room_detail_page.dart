import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'add_room_page.dart';
import 'package:url_launcher/url_launcher.dart';



class RoomDetailPage extends StatefulWidget {
  final String houseId;
  final String roomId;
  final Map<String, dynamic> houseData;
  final Map<String, dynamic> initialRoomData;

  const RoomDetailPage({
    super.key,
    required this.houseId,
    required this.roomId,
    required this.houseData,
    required this.initialRoomData,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _roomData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _roomData = widget.initialRoomData;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _editRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoomPage(
          houseId: widget.houseId,
          houseData: widget.houseData,
          roomId: widget.roomId,
          initialRoomData: _roomData,
        ),
      ),
    );
  }

  Future<void> _deleteRoom() async {
    final act = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phòng này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (act == true) {
      try {
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('rooms')
            .doc(widget.roomId)
            .delete();
            
        // Decrease roomCount
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .update({
          'roomCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phòng'), backgroundColor: Colors.red));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
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
          children: [
            const Text('Chi tiết phòng', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${_roomData['roomName']} - #${widget.roomId.substring(0, 6).toUpperCase()}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00A651),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF00A651),
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Hóa đơn'),
            Tab(text: 'Lịch sử'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            _roomData = snapshot.data!.data() as Map<String, dynamic>;
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(),
              const Center(child: Text("Logic hóa đơn đang phát triển")),
              const Center(child: Text("Logic lịch sử đang phát triển")),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTab() {
    final services = _roomData['services'] as List<dynamic>? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Basic status banner
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mã kết nối phòng - Dành cho APP khách thuê', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.houseData['name'] ?? 'Không rõ nhà trọ', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(_roomData['status'] ?? 'Đang trống', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text("Chờ kỳ thu tới", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                // NÚT KẾT NỐI ZALO (Nếu đã thuê mà chưa có ID Zalo)
                if (_roomData['status'] == 'Đã thuê' && (_roomData['zaloUid'] == null || _roomData['zaloUid'].toString().isEmpty)) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "⚠️ Khách thuê chưa kết nối Zalo nhận thông báo tự động.",
                    style: TextStyle(color: Colors.deepOrange, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final phone = _roomData['tenantPhone'] ?? '';
                        if (phone.isEmpty) return;

                        final connectText = "Ketnoi $phone";
                        // Copy vào clipboard
                        await Clipboard.setData(ClipboardData(text: connectText));

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã copy: "$connectText". Hãy dán vào Zalo!'))
                          );
                        }

                        final url = Uri.parse("https://zalo.me/389808064785934940?text=Ketnoi%20$phone");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },

                      icon: const Icon(Icons.wechat_rounded, color: Colors.white),
                      label: const Text("Kết nối Zalo ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0068FF), // Màu xanh Zalo
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
                // HIỂN THỊ TRẠNG THÁI ĐÃ KẾT NỐI
                if (_roomData['zaloUid'] != null && _roomData['zaloUid'].toString().isNotEmpty) ...[
                   const SizedBox(height: 12),
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text("Đã kết nối Zalo nhận thông báo hằng tháng (ID: ${_roomData['zaloUid']})", style: const TextStyle(fontSize: 12, color: Colors.blue))),
                      ],
                    ),
                   ),
                ],
              ],
            ),
          ),

          
          const SizedBox(height: 12),
          
          // Thông tin phòng header
          _buildSectionHeader(
            icon: Icons.tag,
            title: 'Thông tin phòng',
            subtitle: 'Thông tin cơ bản phòng trọ',
            action: OutlinedButton.icon(
              onPressed: _editRoom,
              icon: const Icon(Icons.edit, size: 16, color: Colors.black87),
              label: const Text('Sửa', style: TextStyle(color: Colors.black87)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          
          // Thong tin phong detail Grid
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildInfoCard('Tên phòng', _roomData['roomName'] ?? ''),
                _buildInfoCard('Nhóm', 'Tầng ${_roomData['floor'] ?? ''}'),
                _buildInfoCard('Giá thuê', '${_formatCurrency((_roomData['price'] as num?)?.toDouble() ?? 0)} đ'),
                _buildInfoCard('Diện tích', '${(_roomData['area'] as num?)?.toDouble() ?? 0} m2'),
                _buildInfoCard('Giới tính ưu tiên', _roomData['priority'] ?? 'Tất cả'),
                _buildInfoCard('Ngày lập hóa đơn', 'Ngày ${_roomData['billingCycleDay'] ?? 1}', valueColor: Colors.deepOrange),
              ],
            ),
          ),

          const SizedBox(height: 12),
          
          // Dich vu phong header
          _buildSectionHeader(
            icon: Icons.tag,
            title: 'Dịch vụ của phòng',
            subtitle: 'Phòng đang sử dụng và được tính vào hóa đơn hàng tháng',
          ),
          
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: services.isEmpty
                ? const Text('Chưa có dịch vụ nào', style: TextStyle(color: Colors.black54))
                : Column(
                    children: services.map<Widget>((svc) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(svc['name'] ?? '', style: const TextStyle(fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('${_formatCurrency((svc['price'] as num?)?.toDouble() ?? 0)} đ/1 ${svc['unit'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text('Số hiện tại: ${svc['currentIndex'] ?? ''}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        ],
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteRoom,
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                label: const Text('Xóa phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, {Color valueColor = Colors.black87}) {
    // 50% width minus half spacing
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2, 
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required String subtitle, Widget? action}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
          if (action != null) action,
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
