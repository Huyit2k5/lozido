import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lozido_app/viewmodels/task_viewmodel.dart';
import 'package:lozido_app/presentation/pages/tasks/widgets/task_card.dart';
import 'package:lozido_app/presentation/pages/tasks/add_task_page.dart';
import 'package:lozido_app/data/models/task_model.dart';

class TasksPage extends StatefulWidget {
  final bool isLandlord;
  const TasksPage({super.key, this.isLandlord = true});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Kích hoạt load data phù hợp với vai trò
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadTasks(
        uid: currentUserId,
        isLandlord: widget.isLandlord,
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.isLandlord ? "Quản lý công việc" : "Danh sách công việc",
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String? initialScope;
          if (_selectedTabIndex == 1) {
            initialScope = "Việc cá nhân";
          } else if (_selectedTabIndex == 2) {
            initialScope = "Hệ thống";
          } else {
            initialScope = "Việc quản lý nhà cho thuê";
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskPage(
                isLandlord: widget.isLandlord,
                initialScope: initialScope,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF00A651),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  int _getUncompletedCountForTab(int tabIndex, TaskViewModel provider, String? currentUserId) {
    final allTasks = widget.isLandlord 
        ? provider.tasks 
        : provider.getTasksByCreator(currentUserId ?? "");
    return allTasks.where((t) {
      final isUncompleted = t.status == TaskStatus.newRequest || t.status == TaskStatus.pendingTermination;
      if (!isUncompleted) return false;
      if (tabIndex == 0) return t.taskType != "Việc cá nhân" && t.taskType != "Hệ thống";
      if (tabIndex == 1) return t.taskType == "Việc cá nhân";
      return t.taskType == "Hệ thống";
    }).length;
  }

  Widget _buildTabBar() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5), // Nền xanh dương
        borderRadius: BorderRadius.circular(12),
      ),
      child: Consumer<TaskViewModel>(
        builder: (context, taskProvider, child) => Row(
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.home_outlined,
              title: widget.isLandlord ? "Nhà cho thuê" : "Nhà đang thuê",
              badgeCount: _getUncompletedCountForTab(0, taskProvider, currentUserId),
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.person_outline,
              title: "Cá nhân",
              badgeCount: _getUncompletedCountForTab(1, taskProvider, currentUserId),
            ),
            _buildTabItem(
              index: 2,
              icon: Icons.settings_outlined,
              title: "Hệ thống",
              badgeCount: _getUncompletedCountForTab(2, taskProvider, currentUserId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required IconData icon, required String title, int badgeCount = 0}) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
                    ),
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -5,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<TaskViewModel>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
        }
        
        final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final allTasks = widget.isLandlord 
            ? taskProvider.tasks 
            : taskProvider.getTasksByCreator(currentUserId ?? "");

        List<TaskModel> filteredTasks = [];
        if (_selectedTabIndex == 0) {
          filteredTasks = allTasks.where((t) => t.taskType != "Việc cá nhân" && t.taskType != "Hệ thống").toList();
        } else if (_selectedTabIndex == 1) {
          filteredTasks = allTasks.where((t) => t.taskType == "Việc cá nhân").toList();
        } else if (_selectedTabIndex == 2) {
          filteredTasks = allTasks.where((t) => t.taskType == "Hệ thống").toList();
        }

        if (filteredTasks.isEmpty) {
          String emptyMsg = "Không có công việc nào";
          if (_selectedTabIndex == 1) {
            emptyMsg = "Chưa có việc cá nhân";
          } else if (_selectedTabIndex == 2) {
            emptyMsg = "Chưa có việc hệ thống";
          }
          return Center(
            child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) => TaskCard(
            task: filteredTasks[index],
            isLandlord: widget.isLandlord,
          ),
        );
      },
    );
  }
}
