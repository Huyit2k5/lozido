import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'add_service_page.dart';
import '../../../../viewmodels/service_viewmodel.dart';
import '../../../../viewmodels/house_viewmodel.dart';

class ServiceManagementPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const ServiceManagementPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage> {
  bool _hasInitializedDefaults = false;

  @override
  void initState() {
    super.initState();
    _ensureDefaultServices();
  }

  /// Tự động tạo 2 dịch vụ mặc định nếu collection services rỗng
  Future<void> _ensureDefaultServices() async {
    if (!_hasInitializedDefaults) {
      _hasInitializedDefaults = true;

      // Lấy tất cả roomIds hiện có
      final roomsSnapshot = await context.read<HouseViewModel>().getRooms(widget.houseId);
      final allRoomIds = roomsSnapshot.docs.map((d) => d.id).toList();

      await context.read<ServiceViewModel>().ensureDefaultServices(widget.houseId, allRoomIds);
    }
  }

  IconData _getServiceIcon(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('điện')) return Icons.bolt;
    if (lower.contains('nước')) return Icons.water_drop;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi;
    if (lower.contains('rác')) return Icons.delete_outline;
    if (lower.contains('xe') || lower.contains('giữ xe')) return Icons.two_wheeler;
    return Icons.miscellaneous_services;
  }

  void _confirmDelete(String serviceId, String serviceName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa dịch vụ "$serviceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ServiceViewModel>().deleteService(widget.houseId, serviceId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa dịch vụ'),
                    backgroundColor: Color(0xFF00A651),
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt dịch vụ',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildServiceList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A651),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddServicePage(
                houseId: widget.houseId,
                houseData: widget.houseData,
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildServiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: context.read<ServiceViewModel>().getServicesStream(widget.houseId),
      builder: (context, serviceSnapshot) {
        if (serviceSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00A651)),
          );
        }

        if (serviceSnapshot.hasError) {
          return const Center(
            child: Text('Không thể tải danh sách dịch vụ'),
          );
        }

        final serviceDocs = serviceSnapshot.data?.docs ?? [];

        if (serviceDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black26),
                SizedBox(height: 16),
                Text(
                  'Đang tạo dịch vụ mặc định...',
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
                SizedBox(height: 8),
                CircularProgressIndicator(color: Color(0xFF00A651)),
              ],
            ),
          );
        }

        // Also stream the total room count to determine "all rooms applied" status
        return StreamBuilder<QuerySnapshot>(
          stream: context.read<HouseViewModel>().getRoomsStream(widget.houseId),
          builder: (context, roomSnapshot) {
            final totalRooms = roomSnapshot.data?.docs.length ?? 0;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: serviceDocs.length,
              itemBuilder: (context, index) {
                final doc = serviceDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildServiceCard(doc.id, data, totalRooms);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildServiceCard(String serviceId, Map<String, dynamic> data, int totalRooms) {
    final serviceName = data['serviceName'] ?? 'Dịch vụ';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final unit = data['unit'] ?? '';
    final isMetered = data['isMetered'] ?? false;
    final appliedRooms = List<String>.from(data['appliedRooms'] ?? []);
    final isAppliedAll = totalRooms > 0 && appliedRooms.length >= totalRooms;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getServiceIcon(serviceName),
                color: Colors.black87,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMetered ? 'Theo đồng hồ' : 'Cố định',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatCurrency(price)} Đồng / $unit',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  if (isAppliedAll) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A651),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Đang áp dụng tất cả phòng',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else if (appliedRooms.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Đang áp dụng ${appliedRooms.length} phòng',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            GestureDetector(
              onTap: () => _confirmDelete(serviceId, serviceName),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.remove,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
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
