import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

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
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _getDailySummary(user?.uid, start, end),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("Timeline Error: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error loading data.\nPlease check terminal logs for Firestore Index links.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
             return const Center(child: Text("No data for this date"));
          }

          final data = snapshot.data!;
          final double focusSecs = data['focusSecs'] ?? 0.0;
          final double sleepSecs = data['sleepSecs'] ?? 0.0;
          final List<String> workouts = data['workouts'] ?? [];

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

                // ส่วนแสดงผล Summary Card
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
                       if (workouts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            "- No workouts -",
                             style: TextStyle(color: Colors.white70),
                          ),
                        )
                      else
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

  Stream<Map<String, dynamic>> _getDailySummary(String? uid, DateTime start, DateTime end) {
    if (uid == null) return Stream.value({});

    // Query only by user_id to avoid creating composite indexes manually
    final focusStream = FirebaseFirestore.instance
        .collection('focus_logs')
        .where('user_id', isEqualTo: uid)
        .snapshots();

    final sleepStream = FirebaseFirestore.instance
        .collection('sleep_logs')
        .where('user_id', isEqualTo: uid)
        .snapshots();

    final exerciseStream = FirebaseFirestore.instance
        .collection('exercise_logs')
        .where('user_id', isEqualTo: uid)
        .snapshots();

    return Rx.combineLatest3(
      focusStream,
      sleepStream,
      exerciseStream,
      (QuerySnapshot focusSn, QuerySnapshot sleepSn, QuerySnapshot exerciseSn) {
        double focusSecs = 0;
        double sleepSecs = 0;
        List<String> workouts = [];

        for (var doc in focusSn.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['logged_at'] as Timestamp?;
          if (timestamp == null) continue;
          
          final date = timestamp.toDate();
          if (date.isBefore(start) || date.isAfter(end) || date.isAtSameMomentAs(end)) continue;

          // focus_logs uses 'duration_min'
          focusSecs += (data['duration_min'] ?? 0) * 60; 
        }

        for (var doc in sleepSn.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['logged_at'] as Timestamp?;
          if (timestamp == null) continue;

          final date = timestamp.toDate();
          if (date.isBefore(start) || date.isAfter(end) || date.isAtSameMomentAs(end)) continue;

          // sleep_logs uses 'duration_sec'
          sleepSecs += (data['duration_sec'] ?? 0);
        }

        for (var doc in exerciseSn.docs) {
           final data = doc.data() as Map<String, dynamic>;
           final timestamp = data['logged_at'] as Timestamp?;
           if (timestamp == null) continue;

           final date = timestamp.toDate();
           if (date.isBefore(start) || date.isAfter(end) || date.isAtSameMomentAs(end)) continue;

           String type = data['exercise_type'] ?? 'Unknown';
           String category = data['category'] ?? '';
           // Format: "Push Up (30 reps)" or "Running (30 min)"
           String detail = "";
           if (category == 'Cardio') {
             detail = "${data['duration_min'] ?? 0} min";
           } else {
             detail = "${data['reps'] ?? 0} reps";
           }
           workouts.add("$type ($detail)");
        }
        
        return {
          'focusSecs': focusSecs,
          'sleepSecs': sleepSecs,
          'workouts': workouts,
        };
      },
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
