import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TimelineDetailPage extends StatelessWidget {
  final DateTime selectedDate;
  const TimelineDetailPage({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // สร้างช่วงเวลาเริ่มและจบของวันที่เลือกเพื่อใช้ Query
    DateTime start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    DateTime end = start.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.purple, size: 40),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DAILY SUMMARY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('habits')
            .where('uid', isEqualTo: user?.uid)
            .where('timestamp', isGreaterThanOrEqualTo: start)
            .where('timestamp', isLessThan: end)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // Logic การคำนวณเวลา (ตัวอย่าง)
          double focusSecs = 0;
          double sleepSecs = 0;
          List<String> workouts = [];

          for (var doc in snapshot.data!.docs) {
            String name = doc['name'] ?? '';
            int duration =
                doc['duration'] ?? 0; // สมมติว่าเก็บเป็นวินาทีหรือนาที
            if (name == 'Focus') focusSecs += duration;
            if (name == 'Sleep') sleepSecs += duration;
            if (name.contains('Workout')) workouts.add(doc['activity'] ?? '');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(selectedDate).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ส่วนแสดงผล Summary Card (ตามภาพดีไซน์ของคุณ)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildRow(
                        Colors.orange,
                        "Focus Time",
                        "${(focusSecs / 3600).toStringAsFixed(1)} Hr",
                      ),
                      const SizedBox(height: 10),
                      _buildRow(
                        Colors.blue,
                        "Sleep Time",
                        "${(sleepSecs / 3600).toStringAsFixed(1)} Hr",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ส่วนแสดง Workout History
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Workout History",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...workouts.map(
                        (w) => Text(
                          "• $w",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
