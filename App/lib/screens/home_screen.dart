import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/level_service.dart';
import '../models/avatar_model.dart';
import 'workout_screen.dart';
import 'settings_screen.dart';
import 'pomodoro_screen.dart';
import 'sleep_screen.dart';
import 'timeline_page.dart'; // Import หน้า Timeline ที่ปรับปรุงเป็นแบบมีปฏิทินแล้ว

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final dbService = DatabaseService(uid: user!.uid);

    return StreamBuilder<AvatarModel?>(
      stream: dbService.myAvatar,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData) {
          dbService.createInitialAvatar("My Pet");
          return const Center(child: Text("Creating Pet..."));
        }

        AvatarModel avatar = snapshot.data!;

        // คำนวณเปอร์เซ็นต์ Exp ของแต่ละสาย
        double petExpPct =
            avatar.exp / LevelService.getExpToNextLevel(avatar.level);
        double intExpPct =
            avatar.intelligenceExp /
            LevelService.getExpToNextLevel(avatar.intelligence);
        double mindExpPct =
            avatar.mindExp / LevelService.getExpToNextLevel(avatar.mind);
        double strExpPct =
            avatar.strengthExp /
            LevelService.getExpToNextLevel(avatar.strength);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LV.${avatar.level} ${avatar.name.toUpperCase()}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "HP ${avatar.level * 10}/${avatar.level * 10}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [_buildCoinDisplay(avatar.coins)],
          ),
          body: Column(
            children: [
              // --- ส่วนแสดงสัตว์เลี้ยง (Pet Area) ---
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPetAvatar(),
                    const SizedBox(height: 25),
                    _buildStatBar(
                      "EXP",
                      petExpPct,
                      Colors.greenAccent.shade400,
                      "Lv.${avatar.level}",
                    ),
                    const SizedBox(height: 8),
                    _buildStatBar(
                      "INT",
                      intExpPct,
                      Colors.blueAccent.shade200,
                      "Lv.${avatar.intelligence}",
                    ),
                    const SizedBox(height: 8),
                    _buildStatBar(
                      "MND",
                      mindExpPct,
                      Colors.indigoAccent.shade200,
                      "Lv.${avatar.mind}",
                    ),
                    const SizedBox(height: 8),
                    _buildStatBar(
                      "STR",
                      strExpPct,
                      Colors.redAccent.shade200,
                      "Lv.${avatar.strength}",
                    ),
                  ],
                ),
              ),

              // --- ส่วนเมนูหลัก (Menu Grid) ---
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.9,
                    children: [
                      // ปุ่ม FOCUS
                      _buildMenuButton(
                        context,
                        "assets/icons/clock.png",
                        "FOCUS",
                        Colors.blue.shade50,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PomodoroPage(avatar: avatar),
                          ),
                        ),
                      ),

                      // ปุ่ม SLEEP
                      _buildMenuButton(
                        context,
                        "assets/icons/crescent_moon.png",
                        "SLEEP",
                        Colors.indigo.shade50,
                        Colors.indigo,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SleepPage(avatar: avatar),
                          ),
                        ),
                      ),

                      // ปุ่ม WORKOUT
                      _buildMenuButton(
                        context,
                        "assets/icons/dumbbell.png",
                        "WORKOUT",
                        Colors.orange.shade50,
                        Colors.orange,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutScreen(avatar: avatar),
                          ),
                        ),
                      ),

                      // ปุ่ม TIMELINE (รวม History และปฏิทินไว้ด้วยกัน)
                      _buildMenuButton(
                        context,
                        "assets/icons/calendar.png",
                        "TIMELINE",
                        Colors.purple.shade50,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TimelineCalendarPage(),
                          ), // เข้าสู่หน้า Timeline แบบมีปฏิทิน
                        ),
                      ),

                      // ปุ่มสไตล์ (Coming Soon)
                      _buildMenuButton(
                        context,
                        "assets/icons/shirt.png",
                        "STYLE",
                        Colors.teal.shade50,
                        Colors.teal,
                        null,
                      ),

                      // ปุ่มการตั้งค่า
                      _buildMenuButton(
                        context,
                        "assets/icons/gear.png",
                        "SETTINGS",
                        Colors.grey.shade50,
                        Colors.grey,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Widget ส่วนประกอบอื่นๆ (คงเดิม) ---
  Widget _buildCoinDisplay(int coins) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      child: Row(
        children: [
          Image.asset(
            "assets/icons/money_bag.png",
            width: 20,
            height: 20,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(width: 4),
          Text(
            "$coins",
            style: TextStyle(
              color: Colors.amber.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatar() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/images/CAT.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, double pct, Color color, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  color: color,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              suffix,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String iconPath,
    String label,
    Color bgColor,
    Color borderColor,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap:
          onTap ??
          () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Coming Soon! 🚧"))),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 35,
              height: 35,
              filterQuality: FilterQuality.none,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
