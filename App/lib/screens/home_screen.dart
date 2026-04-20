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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${avatar.name} House",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showRenameDialog(context, dbService, avatar),
                      child: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  "LV.${avatar.level} ${avatar.name.toUpperCase()} (HP ${avatar.level * 10}/${avatar.level * 10})",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              _buildCoinDisplay(avatar.coins),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // --- ส่วนห้อง Isometric (Room Area) ---
              Expanded(
                flex: 5,
                child: _buildIsometricRoom(context, avatar),
              ),

              // --- ส่วนแสดงสัตว์เลี้ยง (Pet Stats Area) ---
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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

  Widget _buildIsometricRoom(BuildContext context, AvatarModel avatar) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: AspectRatio(
          aspectRatio: 2080 / 1760,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double scaleX = constraints.maxWidth / 2080;
              double scaleY = constraints.maxHeight / 1760;
              return Stack(
                children: [
                  // Combined Room Image
                  Image.asset('assets/room_obj/room.png', fit: BoxFit.contain),

                  // Pet inside room
                  Positioned(
                    left: 1040 * scaleX - (175 * scaleX), // Exact middle of the room X (1040 is 2080/2, 175 is half width 350)
                    top: 1250 * scaleY,  // Middle of the floor Y - moved down further
                    width: 350 * scaleX,
                    height: 350 * scaleY,
                    child: Transform.scale(
                      scale: 2.25,
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Image.asset(
                                'assets/pets/${avatar.species.toLowerCase()}/${avatar.species.toLowerCase()}_stage${avatar.selectedStage < 1 ? 1 : avatar.selectedStage}.png',
                                width: 250 * scaleX,
                                height: 250 * scaleY,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Image.asset('assets/images/CAT.png', width: 250 * scaleX, height: 250 * scaleY, fit: BoxFit.contain),
                              ),
                              if (avatar.equippedHat.isNotEmpty)
                                Positioned(
                                  top: 30 * scaleY,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10 * scaleX, vertical: 5 * scaleY),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8 * scaleX),
                                    ),
                                    child: Text(
                                      avatar.equippedHat.toUpperCase(),
                                      style: TextStyle(color: Colors.white, fontSize: 30 * scaleX, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Hitboxes (Interactive)
                  // Wardrobe -> Style (Coming Soon)
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(1600, 640, 2080, 1360),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StyleScreen(currentAvatar: avatar))),
                  ),
                  // Bed -> Sleep Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(800, 640, 1600, 1200),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SleepPage(avatar: avatar))),
                  ),
                  // Calendar -> Timeline Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(1190, 230, 1370, 480),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimelineCalendarPage())),
                  ),
                  // Desk -> Pomodoro / Focus Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(320, 780, 800, 1270),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PomodoroPage(avatar: avatar))),
                  ),
                  // Trophy -> Achievement (Coming Soon)
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(0, 980, 320, 1440),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Achievement Page Coming Soon! 🚧"))),
                  ),
                  // Dumbell -> Workout Page
                  _buildHitbox(
                    constraints: constraints,
                    rect: const Rect.fromLTRB(80, 1570, 230, 1710),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutScreen(avatar: avatar))),
                  ),
                ],
              );
            },
          ),
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
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep it compact
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

  void _showRenameDialog(BuildContext context, DatabaseService dbService, AvatarModel avatar) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await dbService.updateAvatarName(avatar.id, controller.text.trim());
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
