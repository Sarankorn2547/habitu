import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/avatar_model.dart';
import '../main.dart';
import 'dart:async';

class WorkoutScreen extends StatefulWidget {
  final AvatarModel avatar;
  const WorkoutScreen({super.key, required this.avatar});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Category Selection
  String _selectedCategory = 'Cardio'; // 'Cardio' or 'Weight'
  String _selectedType = 'Running';

  // Inputs
  final _durationController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();

  // Timer Logic
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _isTimerMode = false; // Toggle for Cardio: Manual vs Timer

  final List<String> _cardioTypes = ['Running', 'Cycling', 'Swimming'];
  final List<String> _weightTypes = [
    'Push Up',
    'Sit Up',
    'Weight Lifting',
    'Other',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _durationController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      // Auto-fill duration in minutes (round up)
      int minutes = (_elapsedSeconds / 60).ceil();
      if (minutes == 0 && _elapsedSeconds > 0) minutes = 1;
      _durationController.text = minutes.toString();
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _elapsedSeconds = 0;
      _durationController.clear();
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _updateCategory(String category) {
    setState(() {
      _selectedCategory = category;
      // Reset selected type based on category
      _selectedType = category == 'Cardio'
          ? _cardioTypes.first
          : _weightTypes.first;
      // Reset inputs
      _resetTimer();
      _isTimerMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final dbService = DatabaseService(uid: user!.uid);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.purple, size: 40),
          onPressed: () {
            playClickSound();
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Workout Time",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Category Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildCategoryButton('Cardio', Icons.directions_run),
                  _buildCategoryButton('Weight', Icons.fitness_center),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Exercise Icon
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: _selectedCategory == 'Cardio'
                    ? Colors.orange.shade50
                    : Colors.blue.shade50, // เปลี่ยนสีพื้นหลังตาม category
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedCategory == 'Cardio'
                      ? Colors.orange
                      : Colors.blue,
                  width: 3,
                ),
              ),
              child: Center(
                child: Image.asset(
                  // เช็คเงื่อนไขตรงนี้
                  _selectedCategory == 'Cardio'
                      ? 'assets/icons/stamina.png' // ถ้าเป็น Cardio
                      : 'assets/icons/Muscle.png', // ถ้าเป็น Weight (เปลี่ยน path ตามไฟล์ของคุณ)
                  height: 80, // เพิ่มความสูงจาก 200 เป็น 350
                  width: 80, // กำหนดความกว้างควบคู่ไปด้วย
                ),
              ),
            ),
            SizedBox(height: 20),

            // Exercise Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down_circle,
                    color: Colors.orange,
                  ),
                  items:
                      (_selectedCategory == 'Cardio'
                              ? _cardioTypes
                              : _weightTypes)
                          .map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          })
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val!;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 30),

            // Dynamic Content based on Category
            if (_selectedCategory == 'Cardio')
              _buildCardioContent()
            else
              _buildWeightContent(),

            SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  "Finish & get rewards",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                onPressed: () async {
                  playClickSound();
                   if (_isTimerRunning) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please stop the timer first!"))
                      );
                      return;
                   }

                  // Validate inputs
                  if (_selectedCategory == 'Cardio' &&
                      _durationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter duration")),
                    );
                    return;
                  }
                  if (_selectedCategory == 'Weight' &&
                      _repsController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter reps")),
                    );
                    return;
                  }

                  int duration = int.tryParse(_durationController.text) ?? 0;
                  int sets = int.tryParse(_setsController.text) ?? 0;
                  int reps = int.tryParse(_repsController.text) ?? 0;

                  await dbService.logExerciseAndReward(
                    type: _selectedType,
                    category: _selectedCategory,
                    duration: duration,
                    sets: sets,
                    reps: reps,
                    avatarId: widget.avatar.id,
                    currentAvatar: widget.avatar,
                  );

                  Navigator.pop(context);
                  _showRewardDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category, IconData icon) {
    bool isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          playClickSound();
          _updateCategory(category);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardioContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Manual Input", style: TextStyle(color: Colors.grey)),
            Switch(
              value: _isTimerMode,
              activeThumbColor: Colors.orange,
              onChanged: (val) {
                setState(() {
                  _isTimerMode = val;
                  if (!_isTimerMode) _stopTimer();
                });
              },
            ),
            Text("Timer Mode", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 10),
        if (_isTimerMode) ...[
          Text(
            _formatTime(_elapsedSeconds),
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isTimerRunning)
              FloatingActionButton(
                heroTag: "start",
                backgroundColor: Colors.green,
                onPressed: () {
                  playClickSound();
                  _startTimer();
                },
                child: Icon(Icons.play_arrow),
              ),
              if (_isTimerRunning)
              FloatingActionButton(
                heroTag: "stop",
                backgroundColor: Colors.red,
                onPressed: () {
                  playClickSound();
                  _stopTimer();
                },
                child: Icon(Icons.stop),
              ),
              SizedBox(width: 20),
              FloatingActionButton(
                heroTag: "reset",
                backgroundColor: Colors.grey,
                onPressed: () {
                  playClickSound();
                  _resetTimer();
                },
                child: Icon(Icons.refresh),
              ),
            ],
          ),
        ] else ...[
          _buildInputLabel("Duration (minutes)"),
          _buildTextField(_durationController, Icons.timer_outlined),
        ],
      ],
    );
  }

  Widget _buildWeightContent() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Sets (optional)"),
                  _buildTextField(_setsController, Icons.repeat),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Reps"),
                  _buildTextField(_repsController, Icons.numbers),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _showRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Great job!",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("🎉", style: TextStyle(fontSize: 60)),
            SizedBox(height: 10),
            Text(
              "Pet stats successfully updated!",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              playClickSound();
              Navigator.pop(context);
            },
            child: Text("Awesome",
                style:
                    TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
