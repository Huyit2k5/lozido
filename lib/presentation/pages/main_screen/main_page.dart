import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../home/mail_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MailPage(),
    const Center(child: Text("Màn hình Công việc", style: TextStyle(fontSize: 18))),
    const Center(child: Text("Màn hình Tìm khách", style: TextStyle(fontSize: 18))),
    const Center(child: Text("Màn hình Thêm", style: TextStyle(fontSize: 18))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng IndexedStack để giữ nguyên State của từng trang (không bị load lại mỗi khi chuyển Tab)
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF00A651), // Xanh chủ đạo Lozido
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 ? const Color(0xFFE0F2F1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.home_rounded, color: _selectedIndex == 0 ? const Color(0xFF00A651) : Colors.grey.shade500),
                ),
              ),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_outline_rounded, color: _selectedIndex == 1 ? const Color(0xFF00A651) : Colors.grey.shade500),
              ),
              label: 'Hộp thư',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_outlined, color: _selectedIndex == 2 ? const Color(0xFF00A651) : Colors.grey.shade500),
              ),
              label: 'Công việc',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(Icons.folder_shared_outlined, color: _selectedIndex == 3 ? const Color(0xFF00A651) : Colors.grey.shade500),
              ),
              label: 'Tìm khách',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded, color: _selectedIndex == 4 ? const Color(0xFF00A651) : Colors.grey.shade500),
              ),
              label: 'Thêm +',
            ),
          ],
        ),
      ),
    );
  }
}
