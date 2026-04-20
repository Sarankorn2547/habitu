import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/avatar_model.dart';

class StyleScreen extends StatefulWidget {
  final AvatarModel currentAvatar;

  const StyleScreen({Key? key, required this.currentAvatar}) : super(key: key);

  @override
  _StyleScreenState createState() => _StyleScreenState();
}

class _StyleScreenState extends State<StyleScreen> {
  late String selectedSpecies;
  late int selectedStage;
  late String equippedHat;

  final List<String> availableHats = [
    '', // None
    'cap',
    'crown',
    'bow',
    'glasses'
  ];

  @override
  void initState() {
    super.initState();
    selectedSpecies = widget.currentAvatar.species;
    selectedStage = widget.currentAvatar.selectedStage;
    if (selectedStage < 1) selectedStage = 1;
    equippedHat = widget.currentAvatar.equippedHat;
  }

  void _saveChanges() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final dbService = DatabaseService(uid: user.uid);
      await dbService.updateAvatarStyle(
        avatarId: widget.currentAvatar.id,
        species: selectedSpecies,
        stage: selectedStage,
        hat: equippedHat,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
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
        title: const Text('STYLE YOUR PET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Save', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // Preview Area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Base Pet Image
                   Image.asset(
                     'assets/pets/${selectedSpecies.toLowerCase()}/${selectedSpecies.toLowerCase()}_stage$selectedStage.png',
                     width: 150,
                     height: 150,
                     fit: BoxFit.contain,
                     errorBuilder: (context, error, stackTrace) {
                       return const Icon(Icons.error, size: 50, color: Colors.red);
                     },
                   ),
                   // Optional Hat (Placeholder until assets exist)
                   if (equippedHat.isNotEmpty)
                     Positioned(
                       top: 20,
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.black.withOpacity(0.5),
                           borderRadius: BorderRadius.circular(8)
                         ),
                         child: Text(
                           equippedHat.toUpperCase(),
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ),
                ],
              ),
            ),
          ),
          
          // Selection Area
          Expanded(
            flex: 3,
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.black,
                    indicatorColor: Colors.orange,
                    tabs: [
                      Tab(text: 'Species'),
                      Tab(text: 'Stage'),
                      Tab(text: 'Hats'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSpeciesTab(),
                        _buildStageTab(),
                        _buildHatsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesTab() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSelectableCard(
          title: 'Cat',
          isSelected: selectedSpecies == 'Cat',
          onTap: () => setState(() { selectedSpecies = 'Cat'; }),
          icon: Icons.pets,
        ),
        _buildSelectableCard(
          title: 'Dog',
          isSelected: selectedSpecies == 'Dog',
          onTap: () => setState(() { selectedSpecies = 'Dog'; }),
          icon: Icons.pets,
        ),
      ],
    );
  }

  Widget _buildStageTab() {
    int petLevel = widget.currentAvatar.level;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStageCard(stage: 1, requiredLevel: 1, currentLevel: petLevel),
        const SizedBox(height: 10),
        _buildStageCard(stage: 2, requiredLevel: 10, currentLevel: petLevel),
        const SizedBox(height: 10),
        _buildStageCard(stage: 3, requiredLevel: 30, currentLevel: petLevel),
      ],
    );
  }

  Widget _buildStageCard({required int stage, required int requiredLevel, required int currentLevel}) {
    bool isLocked = currentLevel < requiredLevel;
    bool isSelected = selectedStage == stage;

    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          setState(() { selectedStage = stage; });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unlocks at Level $requiredLevel')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stage $stage', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (isLocked)
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 4),
                  Text('Lv. $requiredLevel', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              )
            else if (isSelected)
              const Icon(Icons.check_circle, color: Colors.orange)
          ],
        ),
      ),
    );
  }

  Widget _buildHatsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: availableHats.length,
      itemBuilder: (context, index) {
        String hat = availableHats[index];
        bool isSelected = equippedHat == hat;
        
        return GestureDetector(
          onTap: () {
            setState(() { equippedHat = hat; });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: hat.isEmpty 
                ? const Text('None', style: TextStyle(fontWeight: FontWeight.bold))
                : Text(hat.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectableCard({required String title, required bool isSelected, required VoidCallback onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.orange : Colors.grey),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.orange : Colors.black)),
          ],
        ),
      ),
    );
  }
}
