import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/avatar_model.dart';

class WorkoutScreen extends StatefulWidget {
  final AvatarModel avatar;
  WorkoutScreen({required this.avatar});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String _selectedType = 'Running';
  final _durationController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();

  final List<String> _cardioTypes = ['Running', 'Cycling', 'Swimming'];
  final List<String> _strengthTypes = [
    'Push Up',
    'Sit Up',
    'Weight Lifting',
    'Other',
  ];

  bool get _isCardio => _cardioTypes.contains(_selectedType);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final dbService = DatabaseService(uid: user!.uid);

    return Scaffold(
      appBar: AppBar(title: Text("Log Workout")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. เลือกประเภทกีฬา
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: [..._cardioTypes, ..._strengthTypes].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedType = val!;
                });
              },
              decoration: InputDecoration(labelText: "Exercise Type"),
            ),
            SizedBox(height: 20),

            // 2. ฟอร์มกรอกข้อมูล เปลี่ยนตามประเภท
            if (_isCardio) ...[
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Duration (Minutes)",
                  icon: Icon(Icons.timer),
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Sets",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Reps",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                controller:
                    _durationController, // ยังให้กรอกเวลาได้เผื่ออยากบันทึก
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Total Duration (Optional)",
                  icon: Icon(Icons.timer),
                ),
              ),
            ],

            SizedBox(height: 30),

            // 3. ปุ่ม Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Finish & Get Rewards"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  // Validate inputs
                  if (_isCardio && _durationController.text.isEmpty) return;
                  if (!_isCardio &&
                      (_setsController.text.isEmpty ||
                          _repsController.text.isEmpty))
                    return;

                  int duration = int.tryParse(_durationController.text) ?? 0;
                  int sets = int.tryParse(_setsController.text) ?? 0;
                  int reps = int.tryParse(_repsController.text) ?? 0;

                  await dbService.logExerciseAndReward(
                    type: _selectedType,
                    duration: duration,
                    sets: sets,
                    reps: reps,
                    avatarId: widget.avatar.id,
                    currentExp: widget.avatar.exp,
                    currentCoin: widget.avatar.coins,
                    currentStrength: widget.avatar.strength,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Great Job! Pet Stats Updated!")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
