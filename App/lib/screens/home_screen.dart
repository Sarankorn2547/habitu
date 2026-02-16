import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/avatar_model.dart';
import 'workout_screen.dart';
import 'settings_screen.dart';
import 'pomodoro_screen.dart';
import 'sleep_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final dbService = DatabaseService(uid: user!.uid);

    return StreamBuilder<AvatarModel?>(
      stream: dbService.myAvatar,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        // ถ้ายังไม่มี Avatar (User ใหม่) ให้สร้างก่อน (ในโค้ดจริงควรไปหน้า create character)
        if (!snapshot.hasData) {
          dbService.createInitialAvatar("My Pet");
          return Center(child: Text("Creating Pet..."));
        }

        AvatarModel avatar = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "LV.${avatar.level} ${avatar.name.toUpperCase()}",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                ),
                child: Row(
                  children: [
                    Text("💰", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Text(
                      "${avatar.coins}",
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // --- Pet Area ---
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Placeholder รูปสัตว์เลี้ยง (Emoji)
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "🦊", // Placeholder Emoji
                          style: TextStyle(fontSize: 100),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Stats Bars
                    _buildStatBar(
                      "EXP",
                      avatar.exp / 100.0,
                      Colors.greenAccent.shade400,
                    ), // สมมติ max exp = 100
                    SizedBox(height: 10),
                    _buildStatBar(
                      "STR",
                      avatar.strength / 50.0,
                      Colors.redAccent.shade200,
                    ),
                    SizedBox(height: 10),
                    _buildStatBar(
                      "FOC",
                      avatar.focus / 50.0,
                      Colors.blueAccent.shade200,
                    ),
                  ],
                ),
              ),

              // --- Menu Grid ---
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.85,
                    children: [
                      // Focus button
                      _buildMenuButton(
                        context,
                        "⏱️",
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

                      // Sleep button
                      _buildMenuButton(
                        context,
                        "😴",
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

                      // Workout button
                      _buildMenuButton(
                        context,
                        "💪",
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
                      _buildMenuButton(
                        context,
                        "👕",
                        "STYLE",
                        Colors.purple.shade50,
                        Colors.purple,
                        null,
                      ),
                      _buildMenuButton(
                        context,
                        "🏆",
                        "AWARDS",
                        Colors.amber.shade50,
                        Colors.amber,
                        null,
                      ),
                      _buildMenuButton(
                        context,
                        "⚙️",
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

  Widget _buildStatBar(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: pct > 1 ? 1 : pct,
                  color: color,
                  backgroundColor: Colors.transparent,
                  minHeight: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String emoji, // Changed from IconData to String for Emoji
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
          ).showSnackBar(SnackBar(content: Text("Coming Soon! 🚧"))),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
