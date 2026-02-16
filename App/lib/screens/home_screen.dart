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

        // Create initial avatar if not exists
        if (!snapshot.hasData) {
          dbService.createInitialAvatar("My Pet");
          return Center(child: Text("Creating Pet..."));
        }

        AvatarModel avatar = snapshot.data!;

        // Calculate Progress
        double petExpPct = avatar.exp / LevelService.getExpToNextLevel(avatar.level);
        double intExpPct = avatar.intelligenceExp / LevelService.getExpToNextLevel(avatar.intelligence);
        double mindExpPct = avatar.mindExp / LevelService.getExpToNextLevel(avatar.mind);
        double strExpPct = avatar.strengthExp / LevelService.getExpToNextLevel(avatar.strength);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LV.${avatar.level} ${avatar.name.toUpperCase()}",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "HP ${avatar.level * 10}/${avatar.level * 10}",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                    // Placeholder Pet Image
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
                      petExpPct,
                      Colors.greenAccent.shade400,
                      "${avatar.exp}/${LevelService.getExpToNextLevel(avatar.level)}",
                    ),
                    SizedBox(height: 10),
                    _buildStatBar(
                      "INT",
                      intExpPct,
                      Colors.blueAccent.shade200,
                      "Dv.${avatar.intelligence}",
                    ),
                    SizedBox(height: 10),
                    _buildStatBar(
                      "MND",
                      mindExpPct,
                      Colors.indigoAccent.shade200,
                      "Lv.${avatar.mind}",
                    ),
                     SizedBox(height: 10),
                    _buildStatBar(
                      "STR",
                      strExpPct,
                      Colors.redAccent.shade200,
                      "Lv.${avatar.strength}",
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

  Widget _buildStatBar(String label, double pct, Color color, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          SizedBox(
            width: 40,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: LinearProgressIndicator(
                      value: pct > 1 ? 1 : (pct < 0 ? 0 : pct),
                      color: color,
                      backgroundColor: Colors.transparent,
                      minHeight: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              suffix,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String emoji,
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
