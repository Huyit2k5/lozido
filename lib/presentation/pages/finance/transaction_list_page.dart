import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lozido_app/core/utils/currency_formatter.dart';

class TransactionListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const TransactionListPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  DateTime _selectedMonth = DateTime.now();
  String _typeFilter = 'Tất cả';
  String _categoryFilter = 'Tất cả';

  // Thời gian: 'Tháng', 'Quý', 'Tùy chỉnh'
  String _periodType = 'Tháng';
  DateTime _customStart = DateTime.now();
  DateTime _customEnd = DateTime.now();

  // Tạm lưu filter trong modal trước khi áp dụng
  DateTime _tempMonth = DateTime.now();
  String _tempType = 'Tất cả';
  String _tempCategory = 'Tất cả';
  String _tempPeriod = 'Tháng';
  DateTime _tempCustomStart = DateTime.now();
  DateTime _tempCustomEnd = DateTime.now();

  final List<String> _incomeCategories = [
    'Thu tiền phòng',
    'Thu tiền hàng tháng',
    'Thu tiền tháng đầu tiên',
    'Thu tiền kết thúc hợp đồng',
    'Thu tiền theo chu kỳ',
  ];

  final List<String> _expenseCategories = [
    'Chi trả tiền điện',
    'Chi trả tiền wifi',
    'Chi phí quản lý',
    'Chi giảm trừ hoá đơn',
  ];

  List<String> get _allCategories {
    if (_tempType == 'Thu') return _incomeCategories;
    if (_tempType == 'Chi') return _expenseCategories;
    return [..._incomeCategories, ..._expenseCategories];
  }

  bool get _hasFilterApplied =>
      _typeFilter != 'Tất cả' || _categoryFilter != 'Tất cả';

  String get _currentQuarter {
    final m = _selectedMonth.month;
    if (m <= 3) return 'Quý 1';
    if (m <= 6) return 'Quý 2';
    if (m <= 9) return 'Quý 3';
    return 'Quý 4';
  }

  String get _periodLabel {
    switch (_periodType) {
      case 'Tháng':
        return "Tháng ${DateFormat('MM, yyyy').format(_selectedMonth)}";
      case 'Quý':
        return "${_currentQuarter}/${_selectedMonth.year}";
      case 'Năm':
        return "Năm ${_selectedMonth.year}";
      case 'Tùy chỉnh':
        return "${DateFormat('dd/MM').format(_customStart)} - ${DateFormat('dd/MM/yy').format(_customEnd)}";
      default:
        return '';
    }
  }

  bool _dateMatchesPeriod(DateTime date) {
    switch (_periodType) {
      case 'Tháng':
        return date.month == _selectedMonth.month && date.year == _selectedMonth.year;
      case 'Quý':
        final quarterStartMonth = ((_currentQuarter.hashCode % 10) - 1) * 3 + 1;
        final start = DateTime(_selectedMonth.year, quarterStartMonth, 1);
        final end = DateTime(_selectedMonth.year, quarterStartMonth + 3, 0); // last day of quarter
        return !date.isBefore(start) && !date.isAfter(end);
      case 'Năm':
        return date.year == _selectedMonth.year;
      case 'Tùy chỉnh':
        return !date.isBefore(_customStart) && !date.isAfter(DateTime(_customEnd.year, _customEnd.month, _customEnd.day, 23, 59, 59));
      default:
        return false;
    }
  }

  void _shiftPeriod(int delta) {
    setState(() {
      switch (_periodType) {
        case 'Tháng':
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
          break;
        case 'Quý':
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta * 3, 1);
          break;
        case 'Năm':
          _selectedMonth = DateTime(_selectedMonth.year + delta, _selectedMonth.month, 1);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text(
          "Thu / chi & Tổng kết",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSummaryBar(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF00A651),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: const Color(0xFFF1F4F8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Filter Icon with Badge
          InkWell(
            onTap: _showFilterModal,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.filter_list, size: 20, color: Colors.black87),
                ),
                if (_hasFilterApplied)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "1",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Time dropdown
          InkWell(
            onTap: _showFilterModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _periodLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    _tempMonth = _selectedMonth;
    _tempType = _typeFilter;
    _tempCategory = _categoryFilter;
    _tempPeriod = _periodType;
    _tempCustomStart = _customStart;
    _tempCustomEnd = _customEnd;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.filter_list, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Lọc thu | chi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                        Text("Thống kê theo tháng/quý/năm", style: TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Thời gian
                const Text("Thời gian", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                // Mở dropdown chọn thời gian
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _tempPeriod,
                      isExpanded: true,
                      isDense: true,
                      items: ['Tháng', 'Quý', 'Năm', 'Tùy chỉnh'].map((p) {
                        return DropdownMenuItem(value: p, child: Text("Theo ${p.toLowerCase()}", style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => _tempPeriod = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Hiển thị theo kỳ
                if (_tempPeriod == 'Tháng')
                  _buildPeriodDatePicker(setModalState, "Tháng ${DateFormat('MM, yyyy').format(_tempMonth)}")
                else if (_tempPeriod == 'Quý')
                  _buildQuarterSelector(setModalState)
                else if (_tempPeriod == 'Năm')
                  _buildYearSelector(setModalState)
                else
                  _buildCustomDateRange(setModalState),
                const SizedBox(height: 20),

                // Loại
                const Text("Loại", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: ['Tất cả', 'Thu', 'Chi'].map((type) {
                    final isSelected = _tempType == type;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: type != 'Chi' ? 8 : 0),
                        child: InkWell(
                          onTap: () {
                            setModalState(() { _tempType = type; _tempCategory = 'Tất cả'; });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Danh mục
                const Text("Danh mục", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ['Tất cả', ..._allCategories].contains(_tempCategory) ? _tempCategory : 'Tất cả',
                      isExpanded: true,
                      isDense: true,
                      items: ['Tất cả', ..._allCategories].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => _tempCategory = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            _tempMonth = DateTime.now();
                            _tempType = 'Tất cả';
                            _tempCategory = 'Tất cả';
                            _tempPeriod = 'Tháng';
                            _tempCustomStart = DateTime.now();
                            _tempCustomEnd = DateTime.now();
                          });
                        },
                        icon: const Icon(Icons.close, size: 18, color: Colors.black87),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        label: const Text("Xóa lọc", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedMonth = _tempMonth;
                            _typeFilter = _tempType;
                            _categoryFilter = _tempCategory;
                            _periodType = _tempPeriod;
                            _customStart = _tempCustomStart;
                            _customEnd = _tempCustomEnd;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.filter_list, size: 18, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A651),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        label: const Text("Lọc thu/chi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodDatePicker(void Function(VoidCallback) setModalState, String label) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _tempMonth,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          helpText: 'Chọn tháng',
        );
        if (picked != null) {
          setModalState(() => _tempMonth = picked);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 18, color: Colors.black54),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterSelector(void Function(VoidCallback) setModalState) {
    final year = _tempMonth.year;
    final currentYear = DateTime.now().year;
    return Column(
      children: [
        // Year row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setModalState(() => _tempMonth = DateTime(year - 1, _tempMonth.month, 1)),
              icon: const Icon(Icons.chevron_left, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Text(
              "$year",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (year < currentYear)
              IconButton(
                onPressed: () => setModalState(() => _tempMonth = DateTime(year + 1, _tempMonth.month, 1)),
                icon: const Icon(Icons.chevron_right, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              )
            else
              const SizedBox(width: 36, height: 36),
          ],
        ),
        const SizedBox(height: 8),
        // Quarter buttons
        Row(
          children: ['Quý 1', 'Quý 2', 'Quý 3', 'Quý 4'].map((q) {
            final m = _tempMonth.month;
            final currentQ = m <= 3 ? 'Quý 1' : m <= 6 ? 'Quý 2' : m <= 9 ? 'Quý 3' : 'Quý 4';
            final selected = q == currentQ;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: q != 'Quý 4' ? 4 : 0),
                child: InkWell(
                  onTap: () {
                    final monthMap = {'Quý 1': 1, 'Quý 2': 4, 'Quý 3': 7, 'Quý 4': 10};
                    setModalState(() => _tempMonth = DateTime(year, monthMap[q]!, 1));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "$q",
                      style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildYearSelector(void Function(VoidCallback) setModalState) {
    final year = _tempMonth.year;
    final currentYear = DateTime.now().year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => setModalState(() => _tempMonth = DateTime(year - 1, _tempMonth.month, 1)),
          icon: const Icon(Icons.chevron_left, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Text(
          "Năm $year",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (year < currentYear)
          IconButton(
            onPressed: () => setModalState(() => _tempMonth = DateTime(year + 1, _tempMonth.month, 1)),
            icon: const Icon(Icons.chevron_right, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          )
        else
          const SizedBox(width: 36, height: 36),
      ],
    );
  }

  Widget _buildCustomDateRange(void Function(VoidCallback) setModalState) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tempCustomStart,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                helpText: 'Từ ngày',
              );
              if (picked != null) setModalState(() => _tempCustomStart = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(DateFormat('dd/MM/yy').format(_tempCustomStart), textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("đến", style: TextStyle(color: Colors.black54, fontSize: 13)),
        ),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tempCustomEnd,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                helpText: 'Đến ngày',
              );
              if (picked != null) setModalState(() => _tempCustomEnd = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(DateFormat('dd/MM/yy').format(_tempCustomEnd), textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Chưa có giao dịch nào."));
        }

        var docs = snapshot.data!.docs;

        // Lọc theo kỳ
        docs = docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final date = (d['date'] as Timestamp?)?.toDate();
          if (date == null) return false;
          return _dateMatchesPeriod(date);
        }).toList();

        // Lọc theo loại
        if (_typeFilter != 'Tất cả') {
          docs = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return d['type'] == _typeFilter;
          }).toList();
        }

        // Lọc theo danh mục
        if (_categoryFilter != 'Tất cả') {
          docs = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return d['category'] == _categoryFilter;
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text("Không có giao dịch phù hợp."));
        }

        // Nhóm theo ngày
        Map<String, List<QueryDocumentSnapshot>> groupedDocs = {};
        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final date = (d['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateStr = DateFormat('dd/MM/yyyy').format(date);
          if (!groupedDocs.containsKey(dateStr)) {
            groupedDocs[dateStr] = [];
          }
          groupedDocs[dateStr]!.add(doc);
        }

        // Sắp xếp ngày giảm dần
        final sortedKeys = groupedDocs.keys.toList()..sort((a, b) => 
            DateFormat('dd/MM/yyyy').parse(b).compareTo(DateFormat('dd/MM/yyyy').parse(a)));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dayKey = sortedKeys[index];
            final dayDocs = groupedDocs[dayKey]!;
            
            double dayTotal = 0;
            for (var doc in dayDocs) {
              final d = doc.data() as Map<String, dynamic>;
              final amount = (d['amount'] ?? 0).toDouble();
              if (d['type'] == 'Thu') dayTotal += amount;
              else dayTotal -= amount;
            }

            final parsedDate = DateFormat('dd/MM/yyyy').parse(dayKey);
            final dayOfWeek = DateFormat('EEEE', 'vi').format(parsedDate);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${parsedDate.day < 10 ? '0' : ''}${parsedDate.day}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayOfWeek,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Tháng ${parsedDate.month}/${parsedDate.year}",
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Tổng cộng",
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${formatCurrency(dayTotal)} đ",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ...dayDocs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    return Column(
                      children: [
                        _buildTransactionCard(doc.data() as Map<String, dynamic>),
                        if (index < dayDocs.length - 1)
                          const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_circle_outline, color: Colors.green),
                ),
                title: const Text("Thêm phiếu thu", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Thêm khoản thu mới", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTransactionDialog('Thu');
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_circle_outline, color: Colors.red),
                ),
                title: const Text("Thêm phiếu chi", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Thêm khoản chi mới", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTransactionDialog('Chi');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTransactionDialog(String type) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? category = type == 'Thu' ? _incomeCategories.first : _expenseCategories.first;
    String paymentMethod = 'Tiền mặt';
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type == 'Thu' ? "Thêm phiếu thu" : "Thêm phiếu chi",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Danh mục
                const Text("Danh mục", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      items: (type == 'Thu' ? _incomeCategories : _expenseCategories).map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) => setDialogState(() => category = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Số tiền
                const Text("Số tiền", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Nhập số tiền",
                    suffixText: "đ",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                // Ngày
                const Text("Ngày", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 18, color: Colors.black54),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd/MM/yyyy').format(date),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phương thức thanh toán
                const Text("Phương thức thanh toán", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: paymentMethod,
                      isExpanded: true,
                      items: ['Tiền mặt', 'Chuyển khoản'].map((m) {
                        return DropdownMenuItem(value: m, child: Text(m));
                      }).toList(),
                      onChanged: (v) => setDialogState(() => paymentMethod = v ?? 'Tiền mặt'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ghi chú
                const Text("Ghi chú", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: "Ghi chú (không bắt buộc)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Hủy"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(amountCtrl.text.replaceAll('.', '')) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Vui lòng nhập số tiền hợp lệ")),
                            );
                            return;
                          }
                          await FirebaseFirestore.instance
                              .collection('houses')
                              .doc(widget.houseId)
                              .collection('transactions')
                              .add({
                            'type': type,
                            'category': category,
                            'amount': amount,
                            'date': Timestamp.fromDate(date),
                            'note': noteCtrl.text,
                            'paymentMethod': paymentMethod,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Đã thêm phiếu ${type == 'Thu' ? 'thu' : 'chi'} thành công")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A651),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Lưu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final type = data['type'] ?? 'Thu';
    final category = data['category'] ?? '';
    final amount = (data['amount'] ?? 0).toDouble();
    final note = data['note'] ?? '';
    final Timestamp? dateTs = data['date'];
    final dateStr = dateTs != null
        ? DateFormat('dd/MM/yyyy').format(dateTs.toDate())
        : '';
    final isIncome = type == 'Thu';

    IconData icon;
    Color iconColor;
    switch (category) {
      case 'Tiền phòng':
        icon = Icons.home_outlined;
        iconColor = Colors.blue;
        break;
      case 'Thu dịch vụ':
        icon = Icons.miscellaneous_services_outlined;
        iconColor = Colors.teal;
        break;
      case 'Thu cọc':
        icon = Icons.lock_outline;
        iconColor = Colors.indigo;
        break;
      case 'Chi trả tiền điện':
        icon = Icons.bolt_outlined;
        iconColor = Colors.orange;
        break;
      case 'Chi trả tiền wifi':
        icon = Icons.wifi_outlined;
        iconColor = Colors.blue;
        break;
      case 'Chi phí quản lý':
        icon = Icons.admin_panel_settings_outlined;
        iconColor = Colors.purple;
        break;
      case 'Chi giảm trừ hoá đơn':
        icon = Icons.discount_outlined;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.receipt_long_outlined;
        iconColor = Colors.grey;
    }

    final paymentMethod = data['paymentMethod'] ?? 'Tiền mặt';
    final systemGenerated = data['systemGenerated'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_offer, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  note.isNotEmpty ? note : category,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isIncome ? '+' : '-'}${formatCurrency(amount)} đ",
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(paymentMethod, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('transactions')
          .snapshots(),
      builder: (context, snapshot) {
        double totalIncome = 0;
        double totalExpense = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final date = (d['date'] as Timestamp?)?.toDate();
            if (date == null) continue;
            if (!_dateMatchesPeriod(date)) continue;
            final amount = (d['amount'] ?? 0).toDouble();
            if (d['type'] == 'Thu') {
              totalIncome += amount;
            } else {
              totalExpense += amount;
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem("Khoản thu", Icons.attach_money, Colors.green, totalIncome, isPositive: true),
                _buildSummaryItem("Khoản chi", Icons.arrow_right_alt, Colors.deepOrange, totalExpense, isPositive: false),
                _buildSummaryItem("Tổng kết", Icons.account_balance_wallet, Colors.green, totalIncome - totalExpense, isTotal: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, IconData? icon, Color iconColor, double amount, {bool isPositive = true, bool isTotal = false}) {
    Color amountColor;
    String prefix = '';
    
    if (isTotal) {
      amountColor = amount >= 0 ? Colors.green : Colors.red;
      prefix = '';
    } else {
      if (isPositive) {
        amountColor = Colors.black87;
        prefix = '+ ';
      } else {
        amountColor = Colors.deepOrange;
        prefix = '- ';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "$prefix${formatCurrency(amount.abs())} đ",
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
