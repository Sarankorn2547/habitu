import 'package:flutter/material.dart';
import 'dart:async'; // ต้อง import ตัวนี้เพื่อใช้ Timer
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/avatar_model.dart';
import '../main.dart';

class PomodoroPage extends StatefulWidget {
  final AvatarModel avatar;
  const PomodoroPage({super.key, required this.avatar});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  int settingTime = 25; // เวลาเริ่มต้น (นาที)
  int timeLeft = 0; // เวลาที่เหลือ (วินาที)
  Timer? _timer; // ตัวแปรสำหรับคุมเวลา
  bool isStarted = false;
  bool isPaused = true;

  double _turns = 0.0; // เก็บค่าการพลิกของนาฬิกาทราย

  // ฟังก์ชันเริ่มนับถอยหลัง
  void startTimer() {
    if (_timer != null) _timer!.cancel();

    setState(() {
      isStarted = true;
      isPaused = false;
      _turns += 0.5; // พลิก 180 องศาแค่รอบเดียว
    });

    themePlayer.pause();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          _timer!.cancel();
          isStarted = false;
          _turns += 0.5; // พลิกกลับมาเหมือนเดิม
          themePlayer.resume();
          _showTimeUpDialog(); // แจ้งเตือนเมื่อหมดเวลา
        }
      });
    });
  }

  // ฟังก์ชันหยุดชั่วคราว
  void pauseTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() {
      isPaused = true;
    });
  }

  // ฟังก์ชันแปลงวินาทีเป็นรูปแบบ นาที:วินาที (เช่น 25:00)
  String formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showTimeUpDialog() {
    // Log Data to Firebase
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final dbService = DatabaseService(uid: user.uid);
      dbService.logFocus(
        durationMinutes: settingTime,
        avatarId: widget.avatar.id,
        currentAvatar: widget.avatar,
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("TIMEOVER!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text(
              "You successfully focused for $settingTime minutes!",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "+ EXP & Coins earned!",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("GREAT!"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel(); // เคลียร์หน่วยความจำเมื่อออกจากหน้า
    themePlayer.resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.purple, size: 40),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FOCUSTIME',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ส่วนที่ 1: ช่องแสดงรูปภาพ
            Container(
              width: 250,
              height: 250,
              child: Center(
                child: AnimatedRotation(
                  turns: _turns,
                  duration: const Duration(milliseconds: 600), // ระยะเวลาที่ใช้ในการพลิก
                  curve: Curves.easeInOut,
                  child: Image.asset('assets/icons/hourglass.png'),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ส่วนที่ 2: แสดงผลเวลาและการตั้งค่า
            if (!isStarted) ...[
              const Text(
                'SETTING TIME',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => setState(
                        () => settingTime > 1 ? settingTime-- : null,
                      ),
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '$settingTime',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => settingTime++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    timeLeft = settingTime * 60; // แปลงนาทีเป็นวินาที
                  });
                  startTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Start Focus',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ] else ...[
              // หน้าจอขณะกำลังนับถอยหลัง
              Text(
                '🏁 Goal: $settingTime:00',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                formatTime(timeLeft),
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ปุ่มยกเลิก
                  IconButton(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        isStarted = false;
                        _turns += 0.5; // พลิกกลับมาเหมือนเดิมเมื่อยกเลิก
                      });
                      themePlayer.resume();
                    },
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                  const SizedBox(width: 40),
                  // ปุ่มพัก/ไปต่อ
                  IconButton(
                    onPressed: isPaused ? startTimer : pauseTimer,
                    icon: Icon(
                      isPaused
                          ? Icons.play_circle_fill
                          : Icons.pause_circle_filled,
                      size: 70,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
