import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lozido_app/presentation/pages/auth/auth_wrapper.dart';
import 'package:intl/intl.dart';

class TenantMainPage extends StatefulWidget {
  const TenantMainPage({super.key});

  @override
  State<TenantMainPage> createState() => _TenantMainPageState();
}

class _TenantMainPageState extends State<TenantMainPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Chưa đăng nhập')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final String? houseId = userData['houseId'];
          final String? roomId = userData['roomId'];
          final bool isDefaultPassword = userData['isDefaultPassword'] ?? false;

          if (houseId == null || roomId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa được thêm vào phòng nào.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                    ),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
          }

          return _buildMainContent(houseId, roomId, isDefaultPassword);
        },
      ),
    );
  }

  Widget _buildMainContent(
    String houseId,
    String roomId,
    bool isDefaultPassword,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('houses')
          .doc(houseId)
          .collection('rooms')
          .doc(roomId)
          .snapshots(),
      builder: (context, roomSnapshot) {
        if (!roomSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final roomData =
            roomSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final roomName = roomData['roomName'] ?? 'Phòng';

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('houses').doc(houseId).snapshots(),
          builder: (context, houseSnapshot) {
            final houseData =
                houseSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final houseName = houseData['name'] ?? 'Nhà trọ';
            final int closingDate = houseData['closingDate'] ?? 5;

            return CustomScrollView(
              slivers: [
                _buildSliverHeader(houseId, roomId, roomName, houseName),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressCard(houseId, roomId),
                        if (isDefaultPassword) _buildPasswordWarningBanner(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              color: const Color(0xFF00A651),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Menu thao tác',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Một số thao tác với nhà đang thuê',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        _buildActionMenuGrid(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              color: const Color(0xFF00A651),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Danh mục tính tiền',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dịch vụ & giá tại $houseName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBillingCategory(houseId, roomId, closingDate, roomData, houseData),
                        const SizedBox(height: 24),
                        _buildExpenseManagement(),
                        const SizedBox(height: 16),
                        _buildFindRoommatePlaceholder(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  color: const Color(0xFF00A651),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Danh sách thành viên',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              child: const Text(
                                'Thêm người +',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMembersSection(houseId, roomId, roomData),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSliverHeader(
    String houseId,
    String roomId,
    String roomName,
    String houseName,
  ) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF00A651),
      expandedHeight: 80.0,
      floating: false,
      pinned: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$roomName / ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        houseName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('houses')
                      .doc(houseId)
                      .collection('rooms')
                      .doc(roomId)
                      .collection('members')
                      .where('uid', isEqualTo: currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String role = 'Thành viên';
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final memberData =
                          snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                      role = memberData['role'] ?? 'Thành viên';
                    }
                    return Row(
                      children: [
                        Text(
                          role == 'Chủ hộ'
                              ? 'Bạn là trưởng phòng'
                              : 'Bạn là thành viên',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.list, color: Colors.white),
          onPressed: () => _logout(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProgressCard(String houseId, String roomId) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('houses')
          .doc(houseId)
          .collection('contracts')
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'Có hiệu lực')
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Hide if no active contract
        }

        final contractData =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final startDateTs = contractData['startDate'] as Timestamp?;
        final endDateTs = contractData['endDate'] as Timestamp?;

        DateTime now = DateTime.now();
        DateTime? start = startDateTs?.toDate();
        DateTime? end = endDateTs?.toDate();

        int monthsStayed = 0;
        int daysStayed = 0;
        double progress = 0.5;

        if (start != null) {
          Duration diff = now.difference(start);
          if (diff.isNegative) {
            monthsStayed = 0;
            daysStayed = 0;
            progress = 0.0;
          } else {
            int totalDays = diff.inDays;
            monthsStayed = totalDays ~/ 30;
            daysStayed = totalDays % 30;

            if (end != null) {
              int totalDuration = end.difference(start).inDays;
              if (totalDuration > 0) {
                progress = totalDays / totalDuration;
                if (progress > 1.0) progress = 1.0;
              }
            } else {
              progress = 1.0; // Vô thời hạn
            }
          }
        }

        final dateFormat = DateFormat('dd/MM/yyyy');
        String startStr = start != null ? dateFormat.format(start) : 'N/A';
        String endStr = end != null ? dateFormat.format(end) : 'Vô thời hạn';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF00A651),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$monthsStayed',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A651),
                                ),
                              ),
                              const Text(
                                'Ng\u00e0y đã ở',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số tháng đã ở',
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text(
                          '$monthsStayed tháng, $daysStayed ngày',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A651),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Color(0xFF81C784),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              end != null && now.isAfter(end)
                                  ? 'Đã hết hạn hợp đồng'
                                  : 'Trong thời hạn hợp đồng',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF81C784),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: Color(0xFF00A651)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            color: Color(0xFF00A651),
                            fontSize: 13,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF00A651),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Ngày vào ở',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            startStr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Ngày kết thúc',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            endStr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: end == null
                                  ? Colors.deepOrange
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, height: 1.4),
                    children: [
                      TextSpan(text: 'Bạn đang sử dụng '),
                      TextSpan(
                        text: 'mật khẩu do chủ nhà tạo',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: '. Vui lòng đổi mật khẩu để bảo mật hơn!'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              // Chuyển đến trang đổi mật khẩu
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đổi mật khẩu ngay', style: TextStyle(color: Colors.blue)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: Colors.blue, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenuGrid() {
    final actions = [
      {'icon': Icons.description_outlined, 'title': 'Hợp đồng\nthuê nhà'},
      {'icon': Icons.receipt_long_outlined, 'title': 'Tất cả\nhóa đơn'},
      {
        'icon': Icons.notifications_active_outlined,
        'title': 'Thông báo từ\nchủ nhà',
      },
      {'icon': Icons.build_circle_outlined, 'title': 'Báo sự cố\nPhản ánh'},
      {'icon': Icons.rule_outlined, 'title': 'Xem nội quy &\nPCCC'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                actions[index]['icon'] as IconData,
                size: 40,
                color: const Color(0xFF81C784),
              ),
              const SizedBox(height: 8),
              Text(
                actions[index]['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillingCategory(String houseId, String roomId, int closingDate, Map<String, dynamic> roomData, Map<String, dynamic> houseData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Closing date card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          children: [
                            const TextSpan(text: 'Ngày '),
                            TextSpan(
                              text: '$closingDate ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: 'chốt tiền thuê'),
                          ],
                        ),
                      ),
                      Text(
                        '$closingDate ngày là hạn chót thanh toán phí',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.deepOrange,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('houses')
                .doc(houseId)
                .collection('contracts')
                .where('roomId', isEqualTo: roomId)
                .limit(1)
                .snapshots(),
            builder: (context, contractSnapshot) {
              // Priority: Contract > Room > House > 0
              double rentPrice = (roomData['rentPrice'] as num?)?.toDouble() ?? 0;
              double deposit = (roomData['depositAmount'] as num?)?.toDouble() ?? 0;
              double waterPrice = (roomData['waterPrice'] as num?)?.toDouble() ?? (houseData['waterPrice'] as num?)?.toDouble() ?? 0;
              double electPrice = (roomData['electricityPrice'] as num?)?.toDouble() ?? (houseData['electricityPrice'] as num?)?.toDouble() ?? 0;

              if (contractSnapshot.hasData &&
                  contractSnapshot.data!.docs.isNotEmpty) {
                final contractData =
                    contractSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                if (contractData['rentPrice'] != null) rentPrice = (contractData['rentPrice'] as num).toDouble();
                if (contractData['depositAmount'] != null) deposit = (contractData['depositAmount'] as num).toDouble();
                if (contractData['waterPrice'] != null) waterPrice = (contractData['waterPrice'] as num).toDouble();
                if (contractData['electricityPrice'] != null) electPrice = (contractData['electricityPrice'] as num).toDouble();
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceItem(
                            Icons.home_outlined,
                            'Tiền thuê',
                            '${_formatCurrency(rentPrice)} đ',
                          ),
                        ),
                        Expanded(
                          child: _buildServiceItem(
                            Icons.anchor_outlined,
                            'Tiền cọc',
                            '${_formatCurrency(deposit)} đ',
                            priceColor: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUtilityItem(
                      Icons.water_drop_outlined,
                      'Tiền nước',
                      'Tính theo đồng hồ',
                      '${_formatCurrency(waterPrice)} đ / Khối',
                      null,
                    ),
                    const SizedBox(height: 12),
                    _buildUtilityItem(
                      Icons.bolt_outlined,
                      'Tiền điện',
                      'Tính theo đồng hồ',
                      '${_formatCurrency(electPrice)} đ / kWh',
                      null,
                    ),
                  ],
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.inbox, color: Colors.black87),
                    label: const Text(
                      'L.sử đồng hồ',
                      style: TextStyle(color: Colors.black87),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF8E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.checklist, color: Color(0xFF00A651)),
                    label: const Text(
                      'D.sách chốt',
                      style: TextStyle(color: Color(0xFF00A651)),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
    IconData icon,
    String title,
    String price, {
    Color priceColor = const Color(0xFF00A651),
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              price,
              style: TextStyle(fontWeight: FontWeight.bold, color: priceColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUtilityItem(
    IconData icon,
    String title,
    String subtitle,
    String price,
    String? status,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline, size: 14, color: Colors.deepOrange),
                  SizedBox(width: 4),
                  Text(
                    'Chưa chốt',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.access_time, size: 14, color: Colors.black87),
                  SizedBox(width: 4),
                  Text(
                    'Số cuối: Chưa có',
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseManagement() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QUẢN LÝ CHI TIÊU',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Tìm hiểu',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.attach_money, color: Color(0xFF00A651)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Quỹ thuê nhà',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '0 đ',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.blue),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Quỹ cá nhân',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '0 đ',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFindRoommatePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1, color: Color(0xFF00A651)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pass lại phòng / Tìm ở ghép',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Đăng tin để tìm bạn cùng phòng hoặc pass phòng',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildMembersSection(String houseId, String roomId, Map<String, dynamic> roomData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('houses')
          .doc(houseId)
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        List<Map<String, dynamic>> memberDocs = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
           memberDocs = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        } else if (roomData['tenantName'] != null && roomData['tenantName'].toString().isNotEmpty) {
           memberDocs.add({
              'name': roomData['tenantName'],
              'phone': roomData['tenantPhone'] ?? 'Chưa cập nhật',
              'role': 'Chủ hộ',
              'status': 'Chưa xác nhận',
              'residenceStatus': 'Chưa đăng ký',
           });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ghi nhận ${memberDocs.length} thành viên',
              style: const TextStyle(color: Color(0xFF00A651)),
            ),
            const SizedBox(height: 12),
            ...memberDocs.map((data) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            if (data['role'] == 'Chủ hộ')
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Thành viên',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                data['role'] == 'Chủ hộ'
                                    ? 'Đại diện hợp đồng - Chủ hộ'
                                    : 'Thành viên',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['phone'] ?? 'Chưa cập nhật',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.deepOrange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Chưa xác nhận',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.deepOrange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Chưa đăng ký tạm trú',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Kết nối thành viên khác banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: const Icon(
                      Icons.reduce_capacity,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Kết nối thành viên khác',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Chia sẻ mã QR để các thành viên khác cùng kết nối với nhau',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black87),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
