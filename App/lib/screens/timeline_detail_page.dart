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

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view details")),
      );
    }

    // Query only by user_id to avoid creating composite indexes manually
    final focusStream = FirebaseFirestore.instance
        .collection('focus_logs')
        .where('user_id', isEqualTo: user.uid)
        .snapshots();

    final sleepStream = FirebaseFirestore.instance
        .collection('sleep_logs')
        .where('user_id', isEqualTo: user.uid)
        .snapshots();

    final exerciseStream = FirebaseFirestore.instance
        .collection('exercise_logs')
        .where('user_id', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        stream: focusStream,
        builder: (context, focusSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: sleepStream,
            builder: (context, sleepSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: exerciseStream,
                builder: (context, exerciseSnapshot) {
                  // Check for waiting state
                  if (focusSnapshot.connectionState == ConnectionState.waiting ||
                      sleepSnapshot.connectionState == ConnectionState.waiting ||
                      exerciseSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Check for errors
                  if (focusSnapshot.hasError ||
                      sleepSnapshot.hasError ||
                      exerciseSnapshot.hasError) {
                    debugPrint("Timeline Error: Focus:${focusSnapshot.error}, Sleep:${sleepSnapshot.error}, Exercise:${exerciseSnapshot.error}");
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

                  // Process Data
                  double focusSecs = 0;
                  double sleepSecs = 0;
                  List<String> workouts = [];

                  // Process Focus Logs
                  if (focusSnapshot.hasData) {
                    for (var doc in focusSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = data['logged_at'] as Timestamp?;
                      if (timestamp == null) continue;
                      
                      final date = timestamp.toDate();
                      if (date.isBefore(start) || date.isAfter(end) || date.isAtSameMomentAs(end)) continue;

                      // focus_logs uses 'duration_min'
                      focusSecs += (data['duration_min'] ?? 0) * 60; 
                    }
                  }

                  // Process Sleep Logs
                  if (sleepSnapshot.hasData) {
                    for (var doc in sleepSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = data['logged_at'] as Timestamp?;
                      if (timestamp == null) continue;

                      final date = timestamp.toDate();
                      if (date.isBefore(start) || date.isAfter(end) || date.isAtSameMomentAs(end)) continue;

                      // sleep_logs uses 'duration_sec'
                      sleepSecs += (data['duration_sec'] ?? 0);
                    }
                  }

                  // Process Exercise Logs
                  if (exerciseSnapshot.hasData) {
                    for (var doc in exerciseSnapshot.data!.docs) {
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
                  }

                  // Check if no data at all (optional, depending on UX preference)
                  // For now, we always show the UI even if 0, like original code
                  // But original code had: if (!snapshot.hasData || snapshot.data == null)
                  // Here we have data but it might be empty list of docs.
                  
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
              );
            },
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
