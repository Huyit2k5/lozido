import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_task_page.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Nhà cho thuê', 'Cá nhân', 'Hệ thống'];
  final List<int> _badges = [1, 0, 0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🔥 ', style: TextStyle(fontSize: 16)),
                Text(
                  'Giải quyết thôi nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
                Icon(Icons.assignment_outlined, color: Color(0xFF4CAF50)),
              ],
            ),
            Text(
              'Quản lý hiệu quả với tính năng việc cần làm',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              tabs: List.generate(_tabs.length, (i) {
                return Tab(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _tabController.index == i
                              ? const Color(0xFF2979FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              i == 0
                                  ? Icons.home_outlined
                                  : i == 1
                                  ? Icons.work_outline
                                  : Icons.person_outline,
                              size: 16,
                              color: _tabController.index == i
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _tabs[i],
                              style: TextStyle(
                                color: _tabController.index == i
                                    ? Colors.white
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_badges[i] > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_badges[i]}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              onTap: (i) => setState(() {}),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          KeepAliveWrapper(child: _buildTaskList('Nhà cho thuê')),
          KeepAliveWrapper(child: _buildTaskList('Việc cá nhân')),
          KeepAliveWrapper(child: _buildTaskList('Hệ thống')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add',
        backgroundColor: const Color(0xFF4CAF50),
        onPressed: () {
          final scopes = ['Nhà cho thuê', 'Việc cá nhân', 'Hệ thống'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddTaskPage(initialScope: scopes[_tabController.index]),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskList(String scope) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('scope', isEqualTo: scope)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }
        final tasks = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, i) {
            final data = tasks[i].data();
            final createdAt = DateTime.parse(data['createdAt']);
            final diff = DateTime.now().difference(createdAt);
            final timeAgo = diff.inSeconds < 60
                ? '${diff.inSeconds} giây trước'
                : diff.inMinutes < 60
                ? '${diff.inMinutes} phút trước'
                : '${diff.inHours} giờ trước';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                data['description']?.toString() ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    _buildInfoRow(
                      Icons.label_outline,
                      'Loại công việc',
                      data['scope']?.toString() ?? '',
                      valueColor: const Color(0xFFFF6600),
                    ),
                    _buildInfoRow(
                      Icons.person_outline,
                      'Người thực hiện',
                      data['assignee']?.toString() ?? '',
                    ),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Thời gian tạo',
                      timeAgo,
                    ),
                    _buildInfoRow(
                      Icons.event_outlined,
                      'Hạn công việc',
                      data['endDate'] != null
                          ? '${DateTime.parse(
                                  data['endDate'],
                                ).day.toString().padLeft(2, '0')}/${DateTime.parse(
                                  data['endDate'],
                                ).month.toString().padLeft(2, '0')}/${DateTime.parse(data['endDate']).year}'
                          : 'Không có',
                    ),
                    _buildInfoRow(
                      Icons.coffee_outlined,
                      'Trạng thái',
                      data['status']?.toString() ?? 'Yêu cầu mới',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: Color(0xFF00A651),
                            ),
                            label: const Text(
                              'Bắt đầu làm',
                              style: TextStyle(color: Color(0xFF00A651)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF00A651)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Xác nhận hủy'),
                                  content: const Text(
                                    'Bạn có chắc muốn xóa công việc này không?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Không'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Có',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('tasks')
                                    .doc(tasks[i].id)
                                    .delete();
                              }
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Hủy bỏ',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Icon(Icons.menu, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: valueColor ?? Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_box.png',
            width: 200,
            errorBuilder: (_, _, _) => const Icon(
              Icons.assignment_outlined,
              size: 120,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có việc cá nhân',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'IRental giúp bạn quản lý các công việc cá nhân của bạn hiệu quả. Bất cứ công việc cá nhân nào bạn cũng có thể tạo và quản lý',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
