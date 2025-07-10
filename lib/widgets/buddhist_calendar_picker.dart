import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BuddhistCalendarPicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const BuddhistCalendarPicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<BuddhistCalendarPicker> createState() => _BuddhistCalendarPickerState();
}

class _BuddhistCalendarPickerState extends State<BuddhistCalendarPicker> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  Future<void> _selectYear() async {
    final firstYear = 1925;
    final lastYear = DateTime.now().year - 6;
    final targetYear = 2530 - 543; // 2530 พ.ศ. = 1987 ค.ศ.
    final itemHeight = 56.0; // ความสูงของ ListTile โดยประมาณ

    final initialIndex = targetYear - firstYear;
    final initialOffset = initialIndex * itemHeight;

    final scrollController = ScrollController(initialScrollOffset: initialOffset);

    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เลือกปี พ.ศ.'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              controller: scrollController,
              itemCount: lastYear - firstYear + 1,
              itemBuilder: (context, index) {
                final year = firstYear + index;
                final yearBE = year + 543;
                return ListTile(
                  title: Center(child: Text('$yearBE')),
                  onTap: () => Navigator.of(context).pop(year),
                  selected: year == _displayedMonth.year,
                  selectedTileColor: Colors.orange[100],
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _displayedMonth = DateTime(picked, 1);
      });
    }
  }

  List<Widget> _buildDayLabels() {
    const days = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];
    return days
        .map((d) => Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold))))
        .toList();
  }

  List<Widget> _buildDayGrid() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final thisDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isSelected = thisDate.year == _selectedDate.year &&
          thisDate.month == _selectedDate.month &&
          thisDate.day == _selectedDate.day;

      dayWidgets.add(GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = thisDate;
          });
          // Call after build to avoid layout timing issues
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onDateSelected(thisDate);
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : null,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ));
    }

    return dayWidgets;
  }

  @override
  Widget build(BuildContext context) {
    final yearBE = _displayedMonth.year + 543;
    final thaiMonth = DateFormat.MMMM('th_TH').format(_displayedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: _goToPreviousMonth, icon: const Icon(Icons.chevron_left)),
            TextButton(
              onPressed: _selectYear,
              child: Text('$thaiMonth $yearBE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton(onPressed: _goToNextMonth, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildDayLabels(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildDayGrid(),
        ),
      ],
    );
  }
}