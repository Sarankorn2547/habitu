import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pomodoro_page.dart';
import 'sleep_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); //
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit U',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'monospace', // ใช้ฟอนต์แนวพิมพ์ดีดเพื่อให้เข้ากับ Pixel Art
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "HELLO,",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "SETHAPAT",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 50),

              // ปุ่มกดไปหน้า Pomodoro (Focustime)
              _buildMenuButton(
                context,
                title: "FOCUSTIME",
                icon: Icons.hourglass_bottom_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PomodoroPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildMenuButton(
                context,
                title: "SLEEP TIME",
                icon: Icons.bedtime_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SleepPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับสร้างปุ่มเมนูสไตล์เดียวกับหน้า Pomodoro
  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(5, 5)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
