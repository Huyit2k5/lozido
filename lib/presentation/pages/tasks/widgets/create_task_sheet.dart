import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lozido_app/presentation/provider/task_provider.dart';
import 'package:lozido_app/models/task_model.dart';

class CreateTaskSheet extends StatefulWidget {
  final TaskModel? taskToEdit;

  const CreateTaskSheet({super.key, this.taskToEdit});

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _taskTypeController;
  late TextEditingController _performerController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  String? _selectedHouse;

  final List<String> _houses = ["Nhà 1", "Nhà 2", "Nhà 3", "Nhà 4", "Nhà 5"];

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _taskTypeController = TextEditingController(text: task?.taskType ?? 'Hợp đồng');
    _performerController = TextEditingController(text: task?.performer ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _selectedDate = task?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _selectedHouse = task?.houseName;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Chỉnh sửa công việc" : "Tạo công việc mới",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Dropdown chọn Nhà
              DropdownButtonFormField<String>(
                value: _selectedHouse,
                decoration: const InputDecoration(
                  labelText: "Chọn Nhà",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                items: _houses.map((String house) {
                  return DropdownMenuItem<String>(
                    value: house,
                    child: Text(house),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHouse = value;
                  });
                },
                hint: const Text("Chọn căn nhà"),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Tiêu đề công việc",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Vui lòng nhập tiêu đề" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Mô tả ngắn",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taskTypeController,
                decoration: const InputDecoration(
                  labelText: "Loại công việc",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Vui lòng nhập loại" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _performerController,
                decoration: const InputDecoration(
                  labelText: "Người thực hiện",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Vui lòng nhập người thực hiện" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Hạn công việc"),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? "CẬP NHẬT" : "TẠO MỚI",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.taskToEdit != null) {
        final updatedTask = TaskModel(
          id: widget.taskToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          taskType: _taskTypeController.text,
          performer: _performerController.text,
          createdAt: widget.taskToEdit!.createdAt,
          deadline: _selectedDate,
          contractEndDate: widget.taskToEdit!.contractEndDate,
          houseName: _selectedHouse,
          status: widget.taskToEdit!.status,
        );
        context.read<TaskProvider>().updateTask(updatedTask);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã cập nhật công việc thành công")),
        );
      } else {
        context.read<TaskProvider>().createNewTask(
              title: _titleController.text,
              description: _descriptionController.text,
              taskType: _taskTypeController.text,
              performer: _performerController.text,
              deadline: _selectedDate,
              createdAt: DateTime.now(),
              houseName: _selectedHouse,
              creatorId: FirebaseAuth.instance.currentUser?.uid,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã tạo công việc mới thành công")),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taskTypeController.dispose();
    _performerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
