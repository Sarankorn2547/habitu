import 'package:flutter/material.dart';
import 'dart:async';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  int secondsPassed = 0; // เก็บเวลาที่นับเดินหน้า
  Timer? _timer;
  bool isSleeping = false; // สถานะว่ากำลังหลับอยู่หรือไม่

  // ฟังก์ชันเริ่ม/หยุดการนับเวลา
  void toggleSleep() {
    setState(() {
      isSleeping = !isSleeping;
    });

    if (isSleeping) {
      // เริ่มนับเวลาเดินหน้า
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          secondsPassed++;
        });
      });
    } else {
      // หยุดนับเวลา
      _timer?.cancel();
    }
  }

  // แปลงวินาทีเป็นรูปแบบ HH:mm:ss (เช่น 00:22:00)
  String formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
          'Sleep Time',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ส่วนแสดงรูปภาพ (น้องแรคคูน) ---
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                // เปลี่ยนเป็น Image.asset('assets/raccoon_sleep.png') เมื่อมีรูปนะครับ
                child: isSleeping
                    ? const Icon(
                        Icons.nightlight_round,
                        size: 100,
                        color: Colors.indigo,
                      )
                    : const Icon(
                        Icons.wb_sunny_rounded,
                        size: 100,
                        color: Colors.orange,
                      ),
              ),
            ),
            const SizedBox(height: 30),

            // --- ส่วนแสดงตัวเลขเวลา ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                formatTime(secondsPassed),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- ปุ่ม Awake / Up ---
            GestureDetector(
              onTap: toggleSleep,
              child: Column(
                children: [
                  Icon(
                    isSleeping
                        ? Icons.visibility
                        : Icons.visibility_off_outlined,
                    size: 60,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isSleeping ? "Up" : "Awake",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
