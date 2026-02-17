import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'timeline_detail_page.dart'; // ไฟล์แสดงรายละเอียดที่เราจะสร้างในข้อ 2

class TimelineCalendarPage extends StatefulWidget {
  const TimelineCalendarPage({super.key});

  @override
  State<TimelineCalendarPage> createState() => _TimelineCalendarPageState();
}

class _TimelineCalendarPageState extends State<TimelineCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.purple, size: 40),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY TIMELINE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(6, 6)),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // ย้ายไปหน้าแสดงรายละเอียดพร้อมส่ง "วันที่เลือก" ไปด้วย
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TimelineDetailPage(selectedDate: selectedDay),
                    ),
                  );
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  decoration: BoxDecoration(color: Colors.red),
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.rectangle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.rectangle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
