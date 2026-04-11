import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_tenant_page.dart';

class TenantDetailPage extends StatefulWidget {
  final String houseId;
  final String contractId;
  final String? tenantSubId; // null = primary tenant from contract
  final String roomName;

  const TenantDetailPage({
    super.key,
    required this.houseId,
    required this.contractId,
    this.tenantSubId,
    required this.roomName,
  });

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic> _tenantData = {};

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  Future<void> _loadTenantData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.tenantSubId != null) {
        // First try to load from 'tenant' array in contract
        final contractDoc = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .doc(widget.contractId)
            .get();

        bool foundInArray = false;
        if (contractDoc.exists) {
          final arr = contractDoc.data()?['tenant'] as List<dynamic>? ?? [];
          final match = arr.firstWhere((e) => (e as Map)['id'] == widget.tenantSubId, orElse: () => null);
          if (match != null) {
            _tenantData = Map<String, dynamic>.from(match as Map);
            _tenantData['tenantName'] = _tenantData['name'] ?? '';
            _tenantData['phoneNumber'] = _tenantData['phone'] ?? '';
            foundInArray = true;
          }
        }

        if (!foundInArray) {
          // Fallback to tenants sub-collection
          final doc = await FirebaseFirestore.instance
              .collection('houses')
              .doc(widget.houseId)
              .collection('contracts')
              .doc(widget.contractId)
              .collection('tenants')
              .doc(widget.tenantSubId)
              .get();

          if (doc.exists) {
            _tenantData = doc.data() ?? {};
            // Normalize field names for sub-tenants
            _tenantData['tenantName'] = _tenantData['name'] ?? '';
            _tenantData['phoneNumber'] = _tenantData['phone'] ?? '';
          }
        }
      } else {
        // Load primary tenant from contract
        final doc = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .doc(widget.contractId)
            .get();

        if (doc.exists) {
          _tenantData = doc.data() ?? {};
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin khách thuê: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getField(String key, {String fallback = 'Không có'}) {
    final val = _tenantData[key];
    if (val == null || val.toString().trim().isEmpty) return fallback;
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tenantName = _getField('tenantName', fallback: 'Chưa xác định');
    final initial = tenantName.isNotEmpty
        ? tenantName.substring(0, 1).toUpperCase()
        : '?';

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
          'Thông tin khách thuê',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A651)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  _buildAvatar(initial),
                  const SizedBox(height: 20),

                  // Main info section
                  _buildMainInfoSection(),
                  const SizedBox(height: 8),

                  // Additional info section
                  _buildAdditionalInfoSection(),
                  const SizedBox(height: 8),

                  // CCCD section
                  _buildCccdSection(),
                  const SizedBox(height: 8),

                  // Vehicle management section
                  _buildVehicleSection(),
                  const SizedBox(height: 8),

                  // Temporary residence section
                  _buildResidenceSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAvatar(String initial) {
    final avatarUrl = _tenantData['avatarUrl']?.toString();
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2196F3),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _buildAvatarText(initial),
                )
              : _buildAvatarText(initial),
        ),
      ),
    );
  }

  Widget _buildAvatarText(String initial) {
    return Container(
      color: const Color(0xFF2196F3),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainInfoSection() {
    final tenantName = _getField('tenantName', fallback: 'Chưa xác định');
    final phone = _getField('phoneNumber', fallback: 'Không có');
    final birthday = _getField('birthday');
    final gender = _getField('gender', fallback: 'Nam');
    final tenantType = _tenantData['isContact'] == true
        ? 'Người liên hệ'
        : 'Khách thuê';
    final isRepresentative = _tenantData['isRepresentative'] == true;
    final hasCompleteDocs = _tenantData['hasCompleteDocs'] == true;
    final hasRegisteredResidence = _tenantData['hasRegisteredResidence'] == true;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Name & Phone
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.person_outline,
                  label: 'Họ & Tên',
                  value: tenantName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Số điện thoại',
                  value: phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Birthday & Gender
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày sinh',
                  value: birthday,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.wc_outlined,
                  label: 'Giới tính',
                  value: gender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type & Representative
          Row(
            children: [
              Expanded(
                child: _buildInfoTileColored(
                  icon: Icons.person_search_outlined,
                  label: 'Loại người thuê',
                  value: tenantType,
                  valueColor: const Color(0xFF00A651),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTileColored(
                  icon: Icons.person_pin_outlined,
                  label: 'Người đại diện hợp đ...',
                  value: isRepresentative ? 'Là đại diện' : 'Không',
                  valueColor: isRepresentative
                      ? const Color(0xFF00A651)
                      : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Document status & Residence
          Row(
            children: [
              Expanded(
                child: _buildStatusTile(
                  icon: Icons.info_outline,
                  label: 'Tình trạng giấy tờ',
                  value: hasCompleteDocs ? 'Đầy đủ' : 'Chưa đầy đủ',
                  isPositive: hasCompleteDocs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusTile(
                  icon: Icons.info_outline,
                  label: 'Tình trạng tạm trú',
                  value:
                      hasRegisteredResidence ? 'Đã đăng ký' : 'Chưa đăng ký',
                  isPositive: hasRegisteredResidence,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    final occupation = _getField('occupation');
    final address = _getField('address');
    final cccd = _getField('cccdNumber');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFullWidthInfoTile(
            icon: Icons.business_center_outlined,
            label: 'Nghề nghiệp',
            value: occupation,
          ),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          _buildFullWidthInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ',
            value: address,
          ),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          _buildFullWidthInfoTile(
            icon: Icons.credit_card_outlined,
            label: 'Số CCCD/Passport',
            value: cccd,
          ),
        ],
      ),
    );
  }

  Widget _buildCccdSection() {
    final cccdDate = _getField('cccdDate');
    final cccdPlace = _getField('cccdPlace');
    final cccdFrontImage = _tenantData['cccdFrontImage']?.toString();
    final cccdBackImage = _tenantData['cccdBackImage']?.toString();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date & Place
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày cấp CCCD/\nPassport',
                  value: cccdDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Nơi cấp CCCD/\nPassport',
                  value: cccdPlace,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CCCD Images
          Row(
            children: [
              Expanded(child: _buildCccdImageBox(cccdFrontImage, 'Mặt trước')),
              const SizedBox(width: 12),
              Expanded(child: _buildCccdImageBox(cccdBackImage, 'Mặt sau')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCccdImageBox(String? imageUrl, String label) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00A651).withValues(alpha: 0.3)),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (ctx, err, stack) => _buildCccdPlaceholder(label),
              ),
            )
          : _buildCccdPlaceholder(label),
    );
  }

  Widget _buildCccdPlaceholder(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 32, color: Colors.green.shade300),
          const SizedBox(height: 6),
          Text(
            'Chưa có hình\nCCCD/Passport',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    final vehicles =
        _tenantData['vehicles'] as List<dynamic>? ?? [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tag, color: Color(0xFF00A651), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý phương tiện',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Quản lý xe của khách thuê',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (vehicles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chưa có phương tiện nào được thêm vào',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...vehicles.map((v) {
              final vehicleData = v as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car_outlined,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${vehicleData['type'] ?? 'Xe'} - ${vehicleData['plate'] ?? ''}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildResidenceSection() {
    final residenceDate = _getField('residenceRegistrationDate');
    final residenceExpiry = _getField('residenceExpiryDate');
    final reportTemplate =
        _getField('reportTemplate', fallback: 'CT01 (Mặc định LOZIDO)');
    final relationship =
        _getField('relationship', fallback: 'Chủ hộ');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tag, color: Color(0xFF00A651), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin tờ khai tạm trú',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thông tin khai báo tạm trú',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày ghi nhận tạm trú',
                  value: residenceDate,
                  valueColor: const Color(0xFF00A651),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày hết hạn tạm trú',
                  value: residenceExpiry,
                  valueColor: const Color(0xFF00A651),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),

          _buildFullWidthInfoTile(
            icon: Icons.description_outlined,
            label: 'Mẫu khai báo',
            value: reportTemplate,
          ),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          _buildFullWidthInfoTile(
            icon: Icons.link_outlined,
            label: 'Quan hệ (Dùng khai báo tạm trú)',
            value: relationship,
          ),
        ],
      ),
    );
  }

  // ──────── Reusable tile widgets ────────

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTileColored({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        border: Border.all(
          color: isPositive
              ? const Color(0xFF00A651).withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isPositive ? const Color(0xFF00A651) : Colors.deepOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive
                        ? const Color(0xFF00A651)
                        : Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPositive
                        ? const Color(0xFF00A651)
                        : Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text(
                  'Đóng',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTenantPage(
                        houseId: widget.houseId,
                        contractId: widget.contractId,
                        tenantSubId: widget.tenantSubId,
                        roomName: widget.roomName,
                        tenantData: Map<String, dynamic>.from(_tenantData),
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadTenantData();
                  }
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text(
                  'Chỉnh sửa khách thuê',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
