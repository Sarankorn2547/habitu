import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/avatar_model.dart';
import '../main.dart';

class SleepPage extends StatefulWidget {
  final AvatarModel avatar;
  const SleepPage({super.key, required this.avatar});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> with WidgetsBindingObserver {
  int secondsPassed = 0; // เก็บเวลาที่นับเดินหน้า
  Timer? _timer;
  bool isSleeping = false; // สถานะว่ากำลังหลับอยู่หรือไม่
  DateTime? _sleepStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isSleeping && _sleepStartTime != null) {
      setState(() {
        secondsPassed = DateTime.now().difference(_sleepStartTime!).inSeconds;
      });
    }
  }

  // ฟังก์ชันเริ่ม/หยุดการนับเวลา
  void toggleSleep() {
    setState(() {
      isSleeping = !isSleeping;
    });

    if (isSleeping) {
      themePlayer.pause();
      _sleepStartTime = DateTime.now();
      secondsPassed = 0;
      // เริ่มนับเวลาเดินหน้า
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_sleepStartTime != null) {
          setState(() {
            secondsPassed = DateTime.now().difference(_sleepStartTime!).inSeconds;
          });
        }
      });
    } else {
      themePlayer.resume();
      // หยุดนับเวลา
      _timer?.cancel();
      if (_sleepStartTime != null) {
        secondsPassed = DateTime.now().difference(_sleepStartTime!).inSeconds;
      }
      _handleWakeUp();
    }
  }

  Future<void> _handleWakeUp() async {
    // Log Data
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final dbService = DatabaseService(uid: user.uid);
      await dbService.logSleep(
        durationSeconds: secondsPassed,
        avatarId: widget.avatar.id,
        currentAvatar: widget.avatar,
      );
    }

    // Show Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("GOOD MORNING!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/sunface.png'),
            const SizedBox(height: 10),
            Text(
              "You slept for ${formatTime(secondsPassed)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "+ EXP & Coins recovered!",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                secondsPassed = 0; // Reset for next sleep
              });
            },
            child: const Text("AWAKE"),
          ),
        ],
      ),
    );
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
              child: Center(
                // เปลี่ยนเป็น Image.asset('assets/raccoon_sleep.png') เมื่อมีรูปนะครับ
                child: isSleeping
                    ? Image.asset('assets/icons/moon-2.png')
                    : Image.asset('assets/icons/sun1.png'),
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
