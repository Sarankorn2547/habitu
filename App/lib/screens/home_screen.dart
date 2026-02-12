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
          appBar: AppBar(
            title: Text("Level ${avatar.level} ${avatar.name}"),
            actions: [
              Chip(label: Text("💰 ${avatar.coins}")),
              SizedBox(width: 10),
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
                    // Placeholder รูปสัตว์เลี้ยง
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.pets, size: 80, color: Colors.brown),
                    ),
                    SizedBox(height: 20),
                    // Stats Bars
                    _buildStatBar(
                      "EXP",
                      avatar.exp / 100.0,
                      Colors.green,
                    ), // สมมติ max exp = 100
                    _buildStatBar(
                      "Strength",
                      avatar.strength / 50.0,
                      Colors.red,
                    ),
                    _buildStatBar("Focus", avatar.focus / 50.0, Colors.blue),
                  ],
                ),
              ),

              // --- Menu Grid ---
              Expanded(
                flex: 3,
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: EdgeInsets.all(10),
                  children: [
                    // Focus button
                    _buildMenuButton(
                      context,
                      Icons.timer,
                      "Focus",
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PomodoroPage()),
                      ),
                    ),

                    // Sleep button
                    _buildMenuButton(
                      context,
                      Icons.bed,
                      "Sleep",
                      Colors.indigo,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SleepPage()),
                      ),
                    ),

                    // Workout button
                    _buildMenuButton(
                      context,
                      Icons.fitness_center,
                      "Workout",
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
                      Icons.checkroom,
                      "Dress Up",
                      Colors.purple,
                      null,
                    ),
                    _buildMenuButton(
                      context,
                      Icons.emoji_events,
                      "Achievement",
                      Colors.amber,
                      null,
                    ),
                    _buildMenuButton(
                      context,
                      Icons.history,
                      "Timeline",
                      Colors.teal,
                      null,
                    ),
                    _buildMenuButton(
                      context,
                      Icons.settings,
                      "Settings",
                      Colors.grey,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
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
  }

  Widget _buildStatBar(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: pct > 1 ? 1 : pct,
              color: color,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap:
            onTap ??
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Coming Soon"))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
