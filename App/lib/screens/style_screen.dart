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

  List<AvatarModel> ownedPets = [];
  List<String> unlockedHats = [];
  int currentCoins = 0;
  bool isLoading = true;

  final List<String> availableSpecies = ['Cat', 'Dog']; // Scalable for future

  @override
  void initState() {
    super.initState();
    selectedSpecies = widget.currentAvatar.species;
    selectedStage = widget.currentAvatar.selectedStage;
    if (selectedStage < 1) selectedStage = 1;
    equippedHat = widget.currentAvatar.equippedHat;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final dbService = DatabaseService(uid: user.uid);
      var allPetsStream = await dbService.avatarCollection.where('user_id', isEqualTo: user.uid).get();
      ownedPets = allPetsStream.docs.map((doc) => AvatarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      var userDoc = await dbService.userCollection.doc(user.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        currentCoins = data['coins'] ?? 0;
        if (data['unlocked_hats'] != null) {
          unlockedHats = List<String>.from(data['unlocked_hats']);
        }
      }
      
      if (mounted) setState(() => isLoading = false);
    }
  }

  AvatarModel? _getOwnedPet(String species) {
    try {
      return ownedPets.firstWhere((pet) => pet.species == species);
    } catch (_) {
      return null;
    }
  }

  void _saveChanges() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final dbService = DatabaseService(uid: user.uid);
      
      AvatarModel? selectedPet = _getOwnedPet(selectedSpecies);
      if (selectedPet != null) {
        if (selectedPet.id != widget.currentAvatar.id) {
          await dbService.switchActivePet(selectedPet.id);
        }
        await dbService.updateAvatarStyle(
          avatarId: selectedPet.id,
          stage: selectedStage,
          hat: equippedHat,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _handleSpeciesTap(String species) {
    if (_getOwnedPet(species) != null) {
       setState(() {
         selectedSpecies = species;
         selectedStage = _getOwnedPet(species)!.selectedStage;
         if (selectedStage < 1) selectedStage = 1;
         equippedHat = _getOwnedPet(species)!.equippedHat;
       });
    } else {
       _promptAdoption(species);
    }
  }

  void _promptAdoption(String species) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Adopt $species?"),
      content: Text("It costs 500 coins to unlock this pet.\n\nYou have: $currentCoins coins."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            if (currentCoins >= 500) {
              Navigator.pop(context); // Close dialog
              setState(() => isLoading = true);
              final user = Provider.of<User?>(context, listen: false)!;
              final dbService = DatabaseService(uid: user.uid);
              await dbService.adoptPet(species, 500);
              if (mounted) Navigator.pop(context); // Close style screen to show new pet
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
            }
          },  
          child: const Text("Adopt (500)"),
        )
      ]
    ));
  }

  void _handleHatTap(String hat) {
    if (hat.isEmpty || unlockedHats.contains(hat)) {
      setState(() { equippedHat = hat; });
    } else {
      _promptHatPurchase(hat);
    }
  }

  void _promptHatPurchase(String hat) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Buy ${hat.toUpperCase()}?"),
      content: Text("It costs 200 coins to unlock this hat.\n\nYou have: $currentCoins coins."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            if (currentCoins >= 200) {
              Navigator.pop(context); // Close dialog
              setState(() => isLoading = true);
              final user = Provider.of<User?>(context, listen: false)!;
              final dbService = DatabaseService(uid: user.uid);
              await dbService.buyHat(hat, 200);
              
              if (mounted) {
                setState(() {
                  unlockedHats.add(hat);
                  currentCoins -= 200;
                  equippedHat = hat;
                  isLoading = false;
                });
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
            }
          },  
          child: const Text("Buy (200)"),
        )
      ]
    ));
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
      body: isLoading ? const Center(child: CircularProgressIndicator()) : Column(
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
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: availableSpecies.map((species) {
            bool isOwned = _getOwnedPet(species) != null;
            bool isSelected = selectedSpecies == species;
            return _buildSelectableCard(
              title: species,
              isSelected: isSelected,
              isLocked: !isOwned,
              onTap: () => _handleSpeciesTap(species),
              icon: Icons.pets,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStageTab() {
    int petLevel = _getOwnedPet(selectedSpecies)?.level ?? 1;
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
        bool isOwned = hat.isEmpty || unlockedHats.contains(hat);
        bool isSelected = equippedHat == hat;
        
        return GestureDetector(
          onTap: () => _handleHatTap(hat),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.shade50 : (isOwned ? Colors.white : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: hat.isEmpty 
                ? const Text('None', style: TextStyle(fontWeight: FontWeight.bold))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isOwned) const Icon(Icons.lock, size: 20, color: Colors.grey),
                      Text(
                        hat.toUpperCase(), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          color: isOwned ? Colors.black : Colors.grey
                        )
                      ),
                      if (!isOwned) const Text('200 Coins', style: TextStyle(fontSize: 10, color: Colors.orange)),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectableCard({required String title, required bool isSelected, bool isLocked = false, required VoidCallback onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : (isLocked ? Colors.grey.shade200 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isLocked ? Icons.lock : icon, size: 40, color: isSelected ? Colors.orange : Colors.grey),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.orange : (isLocked ? Colors.grey : Colors.black))),
            if (isLocked) const Text('500 Coins', style: TextStyle(fontSize: 10, color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}
