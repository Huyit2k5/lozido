import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lozido_app/models/task_model.dart';
import 'package:lozido_app/presentation/provider/task_provider.dart';

class TenantContractPage extends StatelessWidget {
  final Map<String, dynamic> contractData;
  final String contractId;
  final String? houseName;
  final String? roomName;
  final String? tenantName;

  const TenantContractPage({
    super.key,
    required this.contractData,
    required this.contractId,
    this.houseName,
    this.roomName,
    this.tenantName,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final terminationTask = taskProvider.getTerminationTask(contractId);
    final isPending = terminationTask?.status == TaskStatus.pendingTermination;
    final isCompleted = terminationTask?.status == TaskStatus.terminationCompleted;
    final isDenied = terminationTask?.status == TaskStatus.terminationDenied;

    final now = DateTime.now();
    DateTime? start;
    if (contractData['startDate'] is String) {
      try {
        start = DateFormat('dd/MM/yyyy').parse(contractData['startDate']);
      } catch (e) {
        start = null;
      }
    } else if (contractData['startDate'] is Timestamp) {
      start = (contractData['startDate'] as Timestamp).toDate();
    }

    DateTime? end;
    if (contractData['endDate'] is String) {
      try {
        end = DateFormat('dd/MM/yyyy').parse(contractData['endDate']);
      } catch (e) {
        end = null;
      }
    } else if (contractData['endDate'] is Timestamp) {
      end = (contractData['endDate'] as Timestamp).toDate();
    }
    
    DateTime? createdAt;
    if(contractData['createdAt'] is Timestamp) {
      createdAt = (contractData['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = start;
    }

    bool isActive = true;
    if(end != null && now.isAfter(end)) {
        isActive = false;
    }

    String shortId = contractId.length > 5 ? contractId.substring(0, 5).toUpperCase() : contractId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Thông tin hợp đồng', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                   const SizedBox(height: 24),
                   Text(
                      'Hợp đồng (#$shortId)',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        Container(
                           width: 8, height: 8,
                           decoration: BoxDecoration(
                             color: isDenied ? Colors.red : (isCompleted ? Colors.green : (isPending ? Colors.orange : (isActive ? Colors.green : Colors.red))),
                             shape: BoxShape.circle
                           ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                             _getTerminationStatusText(isActive, isPending, isCompleted, isDenied, terminationTask),
                             style: TextStyle(
                               color: isDenied ? Colors.red : (isCompleted ? Colors.green : (isPending ? Colors.black87 : Colors.black54)), 
                               fontSize: 13, 
                               fontWeight: (isPending || isCompleted || isDenied) ? FontWeight.bold : FontWeight.w500
                             ),
                             textAlign: TextAlign.center,
                          ),
                        )
                     ],
                   ),
                   const SizedBox(height: 16),
                   
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         _buildActionButton(Icons.print, 'In / Tải PDF', Colors.black87, null),
                         _buildActionButton(Icons.assignment, 'Xem văn bản', const Color(0xFF00A651), null),
                         _buildActionButton(Icons.share, 'Chia sẻ', Colors.blue, null),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 16),
                   Container(
                     decoration: const BoxDecoration(
                       color: Colors.white,
                       border: Border(
                         top: BorderSide(color: Color(0xFFEEEEEE)),
                         bottom: BorderSide(color: Color(0xFFEEEEEE)),
                       )
                     ),
                     child: Column(
                       children: [
                         _buildInfoRow('Người ký hợp đồng', tenantName ?? 'Chưa cập nhật', valueColor: Colors.blue, valueFontWeight: FontWeight.bold),
                         _buildDivider(),
                         _buildInfoRow('Tổng số thành viên', '${contractData['totalMembers'] ?? 1} \nngười', subtitle: 'Số thành viên đăng ký', richValue: true, valueBoldPart: '${contractData['totalMembers'] ?? 1} '),
                         _buildDivider(),
                         _buildInfoRow('Số tiền cọc', _formatCurrency((contractData['depositAmount'] ?? 0).toDouble()), subtitle: 'Hoàn trả / giảm trừ khi kết thúc h.đồng'),
                         _buildDivider(),
                         _buildInfoRow('Giá trị hợp đồng', _formatCurrency((contractData['rentPrice'] ?? 0).toDouble()), subtitle: 'Tiền thuê nhà'),
                         _buildDivider(),
                         _buildInfoRow('Chu kỳ thu tiền', '${contractData['paymentCycle'] ?? 1} tháng / 1 lần', subtitle: null),
                         _buildDivider(),
                         _buildInfoRow('Ngày đặt cọc', createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt) : 'N/A', subtitle: 'Là ngày lập hợp đồng'),
                         _buildDivider(),
                         _buildInfoRow('Ngày vào ở', start != null ? DateFormat('dd/MM/yyyy').format(start) : 'N/A', subtitle: 'Ngày chính thức dọn vào ở.'),
                         _buildDivider(),
                         _buildInfoRow('Ngày kết thúc hợp đồng', end != null ? DateFormat('dd/MM/yyyy').format(end) : 'Không thời hạn', subtitle: 'Ngày sẽ chấm dứt hợp đồng'),
                         _buildDivider(),
                         _buildInfoRow('Thời gian ở', 'Mới vào ở', subtitle: null, valueColor: const Color(0xFF00A651)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))
            ),
            child: isPending 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "* Chủ nhà đang xem xét yêu cầu báo kết thúc hợp đồng của bạn",
                      style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isCompleted || isDenied) ? Colors.grey : const Color(0xFFE65100),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                        label: Text(
                          isCompleted ? 'Hợp đồng đã kết thúc' : (isDenied ? 'Báo kết thúc lại' : 'Báo kết thúc h.đồng'), 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                        onPressed: isCompleted ? null : () => _handleTerminationReport(context, shortId),
                      ),
                    ),
                  ],
                ),
          )
        ],
      ),
    );
  }

  String _getTerminationStatusText(bool isActive, bool isPending, bool isCompleted, bool isDenied, TaskModel? task) {
    if (isPending) return "Đang báo kết thúc hợp đồng";
    if (isCompleted) return "Chủ nhà đã xác nhận kết thúc hợp đồng";
    if (isDenied) return "Đã từ chối yêu cầu";
    return isActive ? "Trong thời hạn hợp đồng" : "Đã hết hạn hợp đồng";
  }

  void _handleTerminationReport(BuildContext context, String shortId) async {
    final taskProvider = context.read<TaskProvider>();
    
    if (taskProvider.hasPendingTermination(contractId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn đã gửi yêu cầu kết thúc hợp đồng này rồi. Vui lòng chờ xác nhận.")),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận báo kết thúc hợp đồng"),
        content: const Text("Yêu cầu kết thúc hợp đồng sẽ được gửi đến chủ nhà để xác nhận."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Gửi yêu cầu", style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00A651))),
      );
      
      await Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      Navigator.pop(context);

      taskProvider.createNewTask(
        title: "Yêu cầu kết thúc hợp đồng #$shortId",
        description: "Khách thuê đã gửi yêu cầu kết thúc hợp đồng. Vui lòng kiểm tra và xác nhận kết thúc hợp đồng.",
        taskType: "Kết thúc hợp đồng",
        performer: "Chủ nhà",
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        status: TaskStatus.pendingTermination,
        contractId: contractId,
        sender: tenantName ?? 'Khách thuê',
        contractValue: (contractData['rentPrice'] ?? 0).toDouble(),
        deposit: (contractData['depositAmount'] ?? 0).toDouble(),
        creatorId: FirebaseAuth.instance.currentUser?.uid,
        houseName: houseName,
        scope: roomName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi yêu cầu kết thúc hợp đồng thành công"), backgroundColor: Color(0xFF00A651)),
      );
    }
  }

  Widget _buildActionButton(IconData icon, String title, Color iconColor, VoidCallback? onTap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }

  Widget _buildInfoRow(String title, String value, {String? subtitle, Color? valueColor, FontWeight? valueFontWeight, bool richValue = false, String valueBoldPart = ""}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: richValue ? 
                   RichText(
                     textAlign: TextAlign.right,
                     text: TextSpan(
                       style: const TextStyle(color: Colors.black87, fontSize: 15),
                       children: [
                         TextSpan(text: valueBoldPart, style: const TextStyle(fontWeight: FontWeight.bold)),
                         TextSpan(text: value.replaceAll(valueBoldPart, '')),
                       ]
                     )
                   ) :
                   Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? Colors.black87,
                fontWeight: valueFontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
