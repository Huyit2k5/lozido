import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lozido_app/models/task_model.dart';
import 'package:lozido_app/presentation/provider/task_provider.dart';
import 'package:lozido_app/presentation/pages/tasks/widgets/create_task_sheet.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isLandlord;

  const TaskCard({super.key, required this.task, this.isLandlord = true});

  @override
  Widget build(BuildContext context) {
    bool isTerminationTask = task.taskType == "Kết thúc hợp đồng";
    bool canOperate = task.status == TaskStatus.newRequest || task.status == TaskStatus.pendingTermination;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTerminationTask ? Colors.orange : Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTerminationTask ? Icons.warning_rounded : Icons.warning_amber_rounded, 
                    color: Colors.white, 
                    size: 28
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.status == TaskStatus.pendingTermination)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Chờ xác nhận",
                      style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Info block
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.home_outlined,
                    "Vị trí", 
                    "${task.houseName ?? 'Chưa xác định'}${task.scope != null ? ' - ${task.scope}' : ''}", 
                    valueBold: true,
                    isLocation: true,
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildInfoRow(Icons.sell_outlined, "Loại công việc", task.taskType, valueColor: isTerminationTask ? Colors.orange : Colors.green),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildInfoRow(Icons.person_outline, "Người thực hiện", task.performer, valueBold: true),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildInfoRow(Icons.coffee_outlined, "Trạng thái", task.statusText, isStatus: true, statusColor: canOperate ? task.statusColor : Colors.grey),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            if (isTerminationTask)
              Row(
                children: [
                  if (canOperate) ...[
                    if (isLandlord) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleDenyTermination(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Từ chối", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleConfirmTermination(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A651),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text("Xác nhận kết thúc", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // Khách thuê: Nút Hủy yêu cầu
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCancelRequest(context),
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          label: const Text("Hủy yêu cầu", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Trạng thái đã hoàn tất/đã hủy -> Hiển thị nút xám thông báo
                    Expanded(
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          disabledBackgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          task.status == TaskStatus.cancelled ? "Đã hủy yêu cầu" : task.statusText, 
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  _buildMenuButton(context),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: canOperate ? () => _handleConfirm(context) : null,
                      icon: Icon(Icons.check_box_outlined, color: canOperate ? const Color(0xFF00A651) : Colors.grey),
                      label: Text(canOperate ? "Xác nhận" : task.statusText, style: TextStyle(color: canOperate ? const Color(0xFF00A651) : Colors.grey, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: canOperate ? const Color(0xFF00A651) : Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (canOperate)
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleIgnore(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text("Bỏ qua", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  _buildMenuButton(context),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        onPressed: () => _showMenu(context),
        icon: const Icon(Icons.menu, color: Colors.black54),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(),
      ),
    );
  }

  void _handleConfirm(BuildContext context) {
    context.read<TaskProvider>().updateTaskStatus(task.id, TaskStatus.confirmed);
  }

  void _handleIgnore(BuildContext context) {
    context.read<TaskProvider>().updateTaskStatus(task.id, TaskStatus.ignored);
  }

  void _handleConfirmTermination(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận kết thúc"),
        content: const Text("Bạn có chắc chắn muốn xác nhận kết thúc hợp đồng này? Hợp đồng sẽ chuyển sang trạng thái 'Đã kết thúc'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xác nhận", style: TextStyle(color: Color(0xFF00A651)))),
        ],
      ),
    );
    if (confirm == true) {
      context.read<TaskProvider>().confirmTermination(task.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chủ nhà đã xác nhận kết thúc hợp đồng."), backgroundColor: Color(0xFF00A651)),
      );
    }
  }

  void _handleCancelRequest(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hủy yêu cầu"),
        content: const Text("Bạn có chắc chắn muốn hủy yêu cầu kết thúc hợp đồng này? Hợp đồng sẽ quay lại trạng thái bình thường."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Không")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xác nhận hủy", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        // Cập nhật trạng thái thành 'cancelled' thay vì xóa
        await context.read<TaskProvider>().updateTaskStatus(task.id, TaskStatus.cancelled);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã hủy yêu cầu kết thúc hợp đồng."), backgroundColor: Colors.black87),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Không thể hủy yêu cầu: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleDenyTermination(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Từ chối yêu cầu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Vui lòng nhập lý do từ chối:"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Lý do..."),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập lý do")));
                return;
              }
              Navigator.pop(context, true);
            }, 
            child: const Text("Gửi từ chối", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    if (confirm == true) {
      context.read<TaskProvider>().denyTermination(task.id, reasonController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yêu cầu đã bị từ chối."), backgroundColor: Colors.red),
      );
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility_outlined, color: Colors.blue),
            title: const Text("Xem chi tiết"),
            onTap: () {
              Navigator.pop(context);
              _showDetailDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.orange),
            title: const Text("Chỉnh sửa"),
            onTap: () {
              Navigator.pop(context);
              _showEditSheet(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Xóa", style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    bool isTermination = task.taskType == "Kết thúc hợp đồng";
    final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chi tiết công việc"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTermination) ...[
                _detailRow("Mã hợp đồng:", task.contractId ?? "N/A", isTitle: true),
                _detailRow("Người thuê:", task.sender ?? "Khách thuê"),
                _detailRow("Giá trị hợp đồng:", nf.format(task.contractValue ?? 0)),
                _detailRow("Tiền cọc:", nf.format(task.deposit ?? 0)),
                if (task.status == TaskStatus.terminationDenied)
                  _detailRow("Lý do từ chối:", task.denialReason ?? "Không có", valueColor: Colors.red),
              ],
              _detailRow("Vị trí:", "${task.houseName ?? 'Chưa xác định'}${task.scope != null ? ' - ${task.scope}' : ''}"),
              _detailRow("Tiêu đề:", task.title),
              _detailRow("Mô tả:", task.description),
              _detailRow("Trạng thái:", task.statusText, valueColor: task.statusColor),
              _detailRow("Ngày gửi yêu cầu:", DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTitle = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isTitle ? FontWeight.bold : FontWeight.normal, color: valueColor)),
          const Divider(),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CreateTaskSheet(taskToEdit: task, isLandlord: isLandlord),
    );
  }

  Widget _buildInfoRow(IconData? icon, String label, String value, {Color? valueColor, bool valueBold = false, bool isStatus = false, Color? statusColor, bool isLocation = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (isLocation)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_outlined, size: 18, color: Colors.black87),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
              ],
            ),
          const Spacer(),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                ],
              ),
            )
          else
            Text(value, style: TextStyle(color: valueColor ?? Colors.black, fontWeight: valueBold ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
