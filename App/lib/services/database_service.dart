import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/avatar_model.dart';
import 'level_service.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  // Collection Reference
  final CollectionReference avatarCollection = FirebaseFirestore.instance
      .collection('avatars');
  final CollectionReference exerciseCollection = FirebaseFirestore.instance
      .collection('exercise_logs');

  // Stream Avatar
  Stream<AvatarModel?> get myAvatar {
    return avatarCollection
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return AvatarModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>,
            snapshot.docs.first.id,
          );
        });
  }
  // Update Avatar Name
  Future<void> updateAvatarName(String avatarId, String newName) async {
    await avatarCollection.doc(avatarId).update({'name': newName});
  }

  // Create Initial Avatar
  Future<void> createInitialAvatar(String name) async {
    await avatarCollection.add({
      'user_id': uid,
      'name': name,
      'species': 'Cat',
      'level': 1,
      'exp': 0,
      'strength': 1,
      'intelligence': 1,
      'mind': 1,
      'strength_exp': 0,
      'intelligence_exp': 0,
      'mind_exp': 0,
      'coins': 0,
      'selectedStage': 1,
      'equippedHat': '',
    });
  }

  // Update Avatar Style
  Future<void> updateAvatarStyle({
    required String avatarId,
    String? species,
    int? stage,
    String? hat,
  }) async {
    Map<String, dynamic> data = {};
    if (species != null) data['species'] = species;
    if (stage != null) data['selectedStage'] = stage;
    if (hat != null) data['equippedHat'] = hat;
    if (data.isNotEmpty) {
      await avatarCollection.doc(avatarId).update(data);
    }
  }

  // Log Exercise
  Future<void> logExerciseAndReward({
    required String type,
    required String category, // Cardio or Weight
    int? duration,
    int? sets,
    int? reps,
    required String avatarId,
    required AvatarModel currentAvatar, // Pass full model for access to all stats
  }) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Calculate Gains
    int expGained = 0;
    int coinGained = 0;

    if (category == 'Cardio') {
      expGained = LevelService.calculateCardioExp(duration ?? 0);
      coinGained = LevelService.calculateCardioCoins(duration ?? 0);
    } else {
      expGained = LevelService.calculateWeightExp(reps ?? 0);
      coinGained = LevelService.calculateWeightCoins(reps ?? 0);
    }

    // 1. Log
    DocumentReference logRef = exerciseCollection.doc();
    batch.set(logRef, {
      'user_id': uid,
      'exercise_type': type,
      'category': category,
      'duration_min': duration ?? 0,
      'sets': sets ?? 0,
      'reps': reps ?? 0,
      'exp_gained': expGained,
      'logged_at': FieldValue.serverTimestamp(),
    });

    // 2. Update Avatar Stats
    // Update Strength Log logic (Strength Leveling?)
    int newStrengthExp = currentAvatar.strengthExp + expGained;
    int newStrength = currentAvatar.strength;
    
    // Check Strength Level Up
    Map<String, int> strengthLevelUp = LevelService.checkLevelUp(newStrengthExp, newStrength);
    newStrength = strengthLevelUp['newLevel']!;
    newStrengthExp = strengthLevelUp['rolloverExp']!;
    int strengthLevelsGained = strengthLevelUp['levelsGained']!;

    // Update Pet Level
    int newExp = currentAvatar.exp + expGained;
    int newLevel = currentAvatar.level;
    
    Map<String, int> petLevelUp = LevelService.checkLevelUp(newExp, newLevel);
    newLevel = petLevelUp['newLevel']!;
    newExp = petLevelUp['rolloverExp']!;
    int petLevelsGained = petLevelUp['levelsGained']!;

    int newSelectedStage = currentAvatar.selectedStage;
    if (petLevelsGained > 0) {
      if (newLevel >= 30 && currentAvatar.level < 30) {
        newSelectedStage = 3;
      } else if (newLevel >= 10 && currentAvatar.level < 10) {
        newSelectedStage = 2;
      }
    }

    // Total Coins
    int totalCoins = currentAvatar.coins + coinGained;
    // Add Level Up Bonuses
    if (petLevelsGained > 0) {
      totalCoins += (petLevelsGained * 50); // 50 coins per pet level
    }
    if (strengthLevelsGained > 0) {
      totalCoins += (strengthLevelsGained * 20); // 20 coins per stat level
    }

    DocumentReference avatarRef = avatarCollection.doc(avatarId);
    batch.update(avatarRef, {
      'exp': newExp,
      'level': newLevel,
      'strength': newStrength,
      'strength_exp': newStrengthExp,
      'coins': totalCoins,
      'selectedStage': newSelectedStage,
    });

    await batch.commit();
  }
  
  // Log Focus
  Future<void> logFocus({
    required int durationMinutes,
    required String avatarId,
    required AvatarModel currentAvatar,
  }) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    int expGained = LevelService.calculateFocusExp(durationMinutes);
    int coinGained = LevelService.calculateFocusCoins(durationMinutes);

    // 1. Log Focus
    DocumentReference logRef =
        FirebaseFirestore.instance.collection('focus_logs').doc();
    batch.set(logRef, {
      'user_id': uid,
      'duration_min': durationMinutes,
      'exp_gained': expGained,
      'logged_at': FieldValue.serverTimestamp(),
    });

    // 2. Update Avatar
    // Update Intelligence
    int newIntExp = currentAvatar.intelligenceExp + expGained;
    int newInt = currentAvatar.intelligence;
    
    Map<String, int> intLevelUp = LevelService.checkLevelUp(newIntExp, newInt);
    newInt = intLevelUp['newLevel']!;
    newIntExp = intLevelUp['rolloverExp']!;
    int intLevelsGained = intLevelUp['levelsGained']!;

    // Update Pet Level
    int newExp = currentAvatar.exp + expGained;
    int newLevel = currentAvatar.level;
    
    Map<String, int> petLevelUp = LevelService.checkLevelUp(newExp, newLevel);
    newLevel = petLevelUp['newLevel']!;
    newExp = petLevelUp['rolloverExp']!;
    int petLevelsGained = petLevelUp['levelsGained']!;

    int newSelectedStage = currentAvatar.selectedStage;
    if (petLevelsGained > 0) {
      if (newLevel >= 30 && currentAvatar.level < 30) {
        newSelectedStage = 3;
      } else if (newLevel >= 10 && currentAvatar.level < 10) {
        newSelectedStage = 2;
      }
    }

    // Coins
    int totalCoins = currentAvatar.coins + coinGained;
    if (petLevelsGained > 0) totalCoins += (petLevelsGained * 50);
    if (intLevelsGained > 0) totalCoins += (intLevelsGained * 20);

    DocumentReference avatarRef = avatarCollection.doc(avatarId);
    batch.update(avatarRef, {
      'exp': newExp,
      'level': newLevel,
      'intelligence': newInt,
      'intelligence_exp': newIntExp,
      'coins': totalCoins,
      'selectedStage': newSelectedStage,
    });

    await batch.commit();
  }

  // Log Sleep
  Future<void> logSleep({
    required int durationSeconds,
    required String avatarId,
    required AvatarModel currentAvatar,
  }) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int minutes = durationSeconds ~/ 60;

    int expGained = LevelService.calculateSleepExp(minutes);
    int coinGained = LevelService.calculateSleepCoins(minutes);

    // 1. Log Sleep
    DocumentReference logRef =
        FirebaseFirestore.instance.collection('sleep_logs').doc();
    batch.set(logRef, {
      'user_id': uid,
      'duration_sec': durationSeconds,
      'exp_gained': expGained,
      'logged_at': FieldValue.serverTimestamp(),
    });

    // 2. Update Avatar
    // Update Mind
    int newMindExp = currentAvatar.mindExp + expGained;
    int newMind = currentAvatar.mind;

    Map<String, int> mindLevelUp = LevelService.checkLevelUp(newMindExp, newMind);
    newMind = mindLevelUp['newLevel']!;
    newMindExp = mindLevelUp['rolloverExp']!;
    int mindLevelsGained = mindLevelUp['levelsGained']!;

    // Update Pet Level
    int newExp = currentAvatar.exp + expGained;
    int newLevel = currentAvatar.level;

    Map<String, int> petLevelUp = LevelService.checkLevelUp(newExp, newLevel);
    newLevel = petLevelUp['newLevel']!;
    newExp = petLevelUp['rolloverExp']!;
    int petLevelsGained = petLevelUp['levelsGained']!;

    int newSelectedStage = currentAvatar.selectedStage;
    if (petLevelsGained > 0) {
      if (newLevel >= 30 && currentAvatar.level < 30) {
        newSelectedStage = 3;
      } else if (newLevel >= 10 && currentAvatar.level < 10) {
        newSelectedStage = 2;
      }
    }

    // Coins
    int totalCoins = currentAvatar.coins + coinGained;
    if (petLevelsGained > 0) totalCoins += (petLevelsGained * 50);
    if (mindLevelsGained > 0) totalCoins += (mindLevelsGained * 20);

    DocumentReference avatarRef = avatarCollection.doc(avatarId);
    batch.update(avatarRef, {
      'exp': newExp,
      'level': newLevel,
      'mind': newMind,
      'mind_exp': newMindExp,
      'coins': totalCoins,
      'selectedStage': newSelectedStage,
    });

    await batch.commit();
  }

  // Delete All User Data
  Future<void> deleteAllUserData() async {
    // Delete avatars
    final avatars = await avatarCollection.where('user_id', isEqualTo: uid).get();
    for (var doc in avatars.docs) {
      await doc.reference.delete();
    }

    // Delete exercise logs
    final exercises = await exerciseCollection.where('user_id', isEqualTo: uid).get();
    for (var doc in exercises.docs) {
      await doc.reference.delete();
    }

    // Delete focus logs
    final focusLogs = await FirebaseFirestore.instance.collection('focus_logs').where('user_id', isEqualTo: uid).get();
    for (var doc in focusLogs.docs) {
      await doc.reference.delete();
    }

    // Delete sleep logs
    final sleepLogs = await FirebaseFirestore.instance.collection('sleep_logs').where('user_id', isEqualTo: uid).get();
    for (var doc in sleepLogs.docs) {
      await doc.reference.delete();
    }
  }
}
