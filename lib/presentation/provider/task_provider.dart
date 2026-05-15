import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:lozido_app/models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;

  TaskProvider() {
    loadTasks();
  }

  List<TaskModel> get tasks => [..._tasks];
  
  // Đếm số công việc chưa hoàn thành (Yêu cầu mới hoặc Chờ xác nhận)
  int get uncompletedTasksCount => _tasks.where((t) => 
    t.status == TaskStatus.newRequest || 
    t.status == TaskStatus.pendingTermination
  ).length;
  
  // Lọc task theo người tạo (dành cho khách thuê)
  List<TaskModel> getTasksByCreator(String uid) {
    return _tasks.where((t) => t.creatorId == uid).toList();
  }

  // Đếm số công việc chưa hoàn thành cho một người tạo cụ thể
  int getUncompletedCountForCreator(String uid) {
    return _tasks.where((t) => 
      t.creatorId == uid && 
      (t.status == TaskStatus.newRequest || t.status == TaskStatus.pendingTermination)
    ).length;
  }

  bool get isLoading => _isLoading;

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tasks.json');
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(contents);
        _tasks = jsonData.map((item) => TaskModel.fromJson(item)).toList();
      } else {
        _tasks = _getSeedData();
        await saveTasks();
      }
    } catch (e) {
      debugPrint("Lỗi khi tải dữ liệu: $e");
      _tasks = _getSeedData();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveTasks() async {
    try {
      final file = await _localFile;
      final jsonData = _tasks.map((task) => task.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      debugPrint("Lỗi khi lưu dữ liệu: $e");
    }
  }

  List<TaskModel> _getSeedData() {
    return [
      TaskModel(
        id: '1',
        title: "Yêu cầu Báo kết thúc hợp đồng",
        description: "Khách thuê Ako đang yêu cầu Báo kết thúc hợp đồng",
        taskType: "Hợp đồng",
        performer: "Nhan",
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        deadline: DateTime(2026, 4, 18),
        contractEndDate: DateTime(2026, 4, 18),
        houseName: "Nhà 1",
        status: TaskStatus.newRequest,
      ),
      TaskModel(
        id: '2',
        title: "Sửa chữa điều hòa phòng 201",
        description: "Điều hòa không mát, cần thợ kiểm tra",
        taskType: "Sửa chữa",
        performer: "Kỹ thuật",
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        deadline: DateTime.now().add(const Duration(days: 1)),
        contractEndDate: DateTime.now().add(const Duration(days: 30)),
        houseName: "Nhà 2",
        scope: "Phòng 201",
        status: TaskStatus.newRequest,
      ),
    ];
  }

  void addTask(TaskModel task) {
    _tasks.insert(0, task);
    saveTasks();
    notifyListeners();
  }

  void updateTaskStatus(String id, TaskStatus newStatus) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks.removeAt(index);
      task.status = newStatus;
      _tasks.add(task); // Chuyển về cuối
      saveTasks();
      notifyListeners();
    }
  }

  void updateTask(TaskModel updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    saveTasks();
    notifyListeners();
  }

  void createNewTask({
    required String title,
    required String description,
    required String taskType,
    required String performer,
    required DateTime deadline,
    DateTime? executionDate,
    required DateTime createdAt,
    String? houseName,
    String? scope,
    TaskPriority priority = TaskPriority.medium,
    List<String> imagePaths = const [],
    TaskStatus status = TaskStatus.newRequest,
    String? contractId,
    String? sender,
    double? contractValue,
    double? deposit,
    String? creatorId,
  }) {
    final newTask = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      taskType: taskType,
      performer: performer,
      createdAt: createdAt,
      deadline: deadline,
      executionDate: executionDate,
      contractEndDate: deadline.add(const Duration(days: 365)),
      houseName: houseName,
      scope: scope,
      priority: priority,
      imagePaths: imagePaths,
      status: status,
      contractId: contractId,
      sender: sender,
      contractValue: contractValue,
      deposit: deposit,
      creatorId: creatorId,
    );
    addTask(newTask);
  }

  bool hasPendingTermination(String contractId) {
    return _tasks.any((task) => 
      task.contractId == contractId && 
      task.status == TaskStatus.pendingTermination
    );
  }

  TaskModel? getTerminationTask(String contractId) {
    final terminationTasks = _tasks.where((t) => 
      t.contractId == contractId && 
      (t.taskType == "Kết thúc hợp đồng" || t.status == TaskStatus.pendingTermination || t.status == TaskStatus.terminationCompleted || t.status == TaskStatus.terminationDenied)
    ).toList();
    
    if (terminationTasks.isEmpty) return null;
    return terminationTasks.first;
  }

  void confirmTermination(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks.removeAt(index);
      task.status = TaskStatus.terminationCompleted;
      _tasks.add(task);
      saveTasks();
      notifyListeners();
    }
  }

  void denyTermination(String taskId, String reason) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks.removeAt(index);
      task.status = TaskStatus.terminationDenied;
      task.denialReason = reason;
      _tasks.add(task);
      saveTasks();
      notifyListeners();
    }
  }
}
