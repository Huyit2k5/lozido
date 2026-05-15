import 'package:flutter/material.dart';

enum TaskStatus {
  newRequest,
  confirmed,
  ignored,
  pendingTermination,
  terminationCompleted,
  terminationDenied,
}

enum TaskPriority {
  low,
  medium,
  high,
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String taskType;
  final String performer;
  final DateTime createdAt;
  final DateTime deadline;
  final DateTime? executionDate;
  final DateTime contractEndDate;
  final String? houseName;
  final String? scope;
  final TaskPriority priority;
  final List<String> imagePaths;
  TaskStatus status;

  final String? contractId;
  final String? sender;
  String? denialReason;
  final double? contractValue;
  final double? deposit;
  
  // Trường mới để phân quyền hiển thị
  final String? creatorId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.performer,
    required this.createdAt,
    required this.deadline,
    this.executionDate,
    required this.contractEndDate,
    this.houseName,
    this.scope,
    this.priority = TaskPriority.medium,
    this.imagePaths = const [],
    this.status = TaskStatus.newRequest,
    this.contractId,
    this.sender,
    this.denialReason,
    this.contractValue,
    this.deposit,
    this.creatorId,
  });

  Color get statusColor {
    switch (status) {
      case TaskStatus.newRequest:
        return Colors.black87;
      case TaskStatus.confirmed:
        return const Color(0xFF00A651);
      case TaskStatus.ignored:
        return Colors.deepOrange;
      case TaskStatus.pendingTermination:
        return Colors.orange;
      case TaskStatus.terminationCompleted:
        return const Color(0xFF00A651);
      case TaskStatus.terminationDenied:
        return Colors.red;
    }
  }

  String get statusText {
    switch (status) {
      case TaskStatus.newRequest:
        return "Yêu cầu mới";
      case TaskStatus.confirmed:
        return "Đã xác nhận";
      case TaskStatus.ignored:
        return "Đã bỏ qua";
      case TaskStatus.pendingTermination:
        return "Chờ xác nhận";
      case TaskStatus.terminationCompleted:
        return "Đã đồng ý";
      case TaskStatus.terminationDenied:
        return "Đã từ chối yêu cầu";
    }
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.low:
        return "Thấp";
      case TaskPriority.medium:
        return "Trung bình";
      case TaskPriority.high:
        return "Cao";
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'taskType': taskType,
      'performer': performer,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'executionDate': executionDate?.toIso8601String(),
      'contractEndDate': contractEndDate.toIso8601String(),
      'houseName': houseName,
      'scope': scope,
      'priority': priority.index,
      'imagePaths': imagePaths,
      'status': status.index,
      'contractId': contractId,
      'sender': sender,
      'denialReason': denialReason,
      'contractValue': contractValue,
      'deposit': deposit,
      'creatorId': creatorId,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      taskType: json['taskType'],
      performer: json['performer'],
      createdAt: DateTime.parse(json['createdAt']),
      deadline: DateTime.parse(json['deadline']),
      executionDate: json['executionDate'] != null ? DateTime.parse(json['executionDate']) : null,
      contractEndDate: DateTime.parse(json['contractEndDate']),
      houseName: json['houseName'],
      scope: json['scope'],
      priority: TaskPriority.values[json['priority'] ?? 1],
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      status: TaskStatus.values[json['status']],
      contractId: json['contractId'],
      sender: json['sender'],
      denialReason: json['denialReason'],
      contractValue: (json['contractValue'] as num?)?.toDouble(),
      deposit: (json['deposit'] as num?)?.toDouble(),
      creatorId: json['creatorId'],
    );
  }
}
