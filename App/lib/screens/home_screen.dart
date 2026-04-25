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
import 'style_screen.dart';
import 'achievements_screen.dart';
import 'photo_screen.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final dbService = DatabaseService(uid: user!.uid);

    return StreamBuilder<AvatarModel?>(
      stream: dbService.myAvatar,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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
          backgroundColor: const Color(0xFFFFF6E0),
          body: SafeArea(
            child: Stack(
              children: [
                // Body content (Room & Stats)
                Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Added space at top so content isn't fully hidden behind the top bar
                                  const SizedBox(height: 70),
                                  // --- ส่วนห้อง Isometric (Room Area) ---
                                  _buildIsometricRoom(context, avatar),

                                  // --- ส่วนแสดงสัตว์เลี้ยง (Pet Stats Area) ---
                                  Container(
                                    width: double.infinity,
                                    color: const Color(0xFFD1B187),
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Column(
                                      children: [
                                        _buildStatBar(
                                          "EXP",
                                          petExpPct,
                                          Colors.greenAccent.shade400,
                                          "Lv.${avatar.level}",
                                        ),
                                        const SizedBox(height: 12),
                                        _buildStatBar(
                                          "INT",
                                          intExpPct,
                                          Colors.greenAccent.shade400,
                                          "Lv.${avatar.intelligence}",
                                        ),
                                        const SizedBox(height: 12),
                                        _buildStatBar(
                                          "MND",
                                          mindExpPct,
                                          Colors.greenAccent.shade400,
                                          "Lv.${avatar.mind}",
                                        ),
                                        const SizedBox(height: 12),
                                        _buildStatBar(
                                          "STR",
                                          strExpPct,
                                          Colors.greenAccent.shade400,
                                          "Lv.${avatar.strength}",
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Camera / Photo Button
                                  GestureDetector(
                                    onTap: () {
                                      playClickSound();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PhotoScreen(avatar: avatar),
                                        ),
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/photo/camera.png',
                                      width: 60,
                                      height: 60,
                                      filterQuality: FilterQuality.none,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                // Custom Top Bar Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E0).withOpacity(0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      "${avatar.name} House",
                                      style: const TextStyle(
                                        color: Color(0xFF4D4539),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        letterSpacing: 1.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      playClickSound();
                                      _showRenameDialog(context, dbService, avatar);
                                    },
                                    child: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Color(0xFF927442),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "Lv.${avatar.level} ${avatar.name.toUpperCase()} (HP ${avatar.level * 10}/${avatar.level * 10})",
                                style: const TextStyle(
                                  color: Color(0xFF927442),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            StreamBuilder<int>(
                              stream: dbService.myCoins,
                              builder: (context, coinSnap) {
                                return _buildCoinDisplay(coinSnap.data ?? 0);
                              },
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.settings, color: Color(0xFF927442)),
                              onPressed: () {
                                playClickSound();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIsometricRoom(BuildContext context, AvatarModel avatar) {
    return Center(
      child: AspectRatio(
        aspectRatio: 2080 / 1760,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double scaleX = constraints.maxWidth / 2080;
              double scaleY = constraints.maxHeight / 1760;
              
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Image (room_normal.png)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Image.asset('assets/photo/room_normal.png', fit: BoxFit.fitWidth),
                  ),

                  // Combined Room Image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Image.asset('assets/room_obj/room.png', fit: BoxFit.fitWidth),
                  ),

                  // Pet inside room
                  Positioned(
                    left:
                        1040 * scaleX -
                        (175 *
                            scaleX), // Exact middle of the room X (1040 is 2080/2, 175 is half width 350)
                    top:
                        1250 *
                        scaleY, // Middle of the floor Y - moved down further
                    width: 350 * scaleX,
                    height: 350 * scaleY,
                    child: Transform.scale(
                      scale: 2.25,
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(
                        child: avatar.equippedHat.isNotEmpty
                            ? Image.asset(
                                'assets/pet_with_hat/${avatar.species.toLowerCase()}_stage${avatar.selectedStage < 1 ? 1 : avatar.selectedStage}/${avatar.equippedHat}.png',
                                width: 250 * scaleX,
                                height: 250 * scaleY,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Image.asset(
                                  'assets/pets/${avatar.species.toLowerCase()}/${avatar.species.toLowerCase()}_stage${avatar.selectedStage < 1 ? 1 : avatar.selectedStage}.png',
                                  width: 250 * scaleX,
                                  height: 250 * scaleY,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c2, e2, s2) => Image.asset(
                                    'assets/images/CAT.png',
                                    width: 250 * scaleX,
                                    height: 250 * scaleY,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : Image.asset(
                                'assets/pets/${avatar.species.toLowerCase()}/${avatar.species.toLowerCase()}_stage${avatar.selectedStage < 1 ? 1 : avatar.selectedStage}.png',
                                width: 250 * scaleX,
                                height: 250 * scaleY,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Image.asset(
                                  'assets/images/CAT.png',
                                  width: 250 * scaleX,
                                  height: 250 * scaleY,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Hitboxes (Interactive)
                  // Wardrobe -> Style (Coming Soon)
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(1590, 630, 2080, 1370),
                    onTap: () {
                      playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StyleScreen(currentAvatar: avatar),
                        ),
                      );
                    },
                  ),
                  // Bed -> Sleep Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(780, 620, 1620, 1220),
                    onTap: () {
                      playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SleepPage(avatar: avatar),
                        ),
                      );
                    },
                  ),
                  // Calendar -> Timeline Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(1170, 210, 1390, 500),
                    onTap: () {
                      playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TimelineCalendarPage(),
                        ),
                      );
                    },
                  ),
                  // Desk -> Pomodoro / Focus Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(300, 760, 820, 1290),
                    onTap: () {
                      playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PomodoroPage(avatar: avatar),
                        ),
                      );
                    },
                  ),
                  // Trophy -> Achievement
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(0, 960, 340, 1460),
                    onTap: () {
                      playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AchievementsScreen(),
                        ),
                      );
                    },
                  ),
                  // Dumbell -> Workout Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(60, 1450, 350, 1730),
                    onTap: () {
                      playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutScreen(avatar: avatar),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
    );
  }

  Widget _buildHitbox({
    required BoxConstraints constraints,
    required Rect rect,
    required VoidCallback onTap,
  }) {
    // Original canvas size
    const double originalWidth = 2080;
    const double originalHeight = 1760;

    // Scale factors based on current container size
    double scaleX = constraints.maxWidth / originalWidth;
    double scaleY = constraints.maxHeight / originalHeight;

    return Positioned(
      left: rect.left * scaleX,
      top: rect.top * scaleY,
      width: rect.width * scaleX,
      height: rect.height * scaleY,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Set to Colors.transparent for production, or Colors.red.withOpacity(0.5) to debug hitboxes!
          color: Colors.transparent,
        ),
      ),
    );
  }

  // --- Widget ส่วนประกอบอื่นๆ (คงเดิม) ---
  Widget _buildCoinDisplay(int coins) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0D5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF927442), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            style: const TextStyle(
              color: Color(0xFF927442),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
              style: const TextStyle(
                color: Color(0xFF4D4539),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white),
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
            width: 40,
            child: Text(
              suffix,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF4D4539),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    DatabaseService dbService,
    AvatarModel avatar,
  ) {
    TextEditingController controller = TextEditingController(text: avatar.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Pet"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new name"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                playClickSound();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await dbService.updateAvatarName(
                    avatar.id,
                    controller.text.trim(),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
