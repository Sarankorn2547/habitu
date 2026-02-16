class AvatarModel {
  String id;
  String userId;
  String name;
  String species;
  int level;
  int exp; // Percent progress to next level (or absolute distinct from total?) 
           // Implementation Plan says: `exp` remains as "Pet Total EXP" but LevelService uses it as "Current Progress".
           // Let's stick to "Current EXP towards next level" to match typical RPGs, or "Total Accumulated EXP"?
           // LevelService logic `exp >= requiredExp` implies `exp` is current progress.
           // However, to keep it simple, let's treat `exp` in model as "Current EXP toward next level".
  
  // Stats
  int strength;
  int intelligence; // Was focus
  int mind;
  
  // Stat EXP (Progress to next stat point) - Optional, 
  // User asked: "the focus time would gain exp in growth rate... like if they focus under 30 minute they will gain 1 exp per minute"
  // And: "intelligence come from focus exp"
  // This implies Stats specific EXPs might just be the Stats themselves?
  // "strength come from workout exp" -> Strength Level?
  // User said: "determine how much experience points (EXP) are required to level up in each type"
  // So stats also have levels!
  // Let's add exp counters for stats.
  int strengthExp;
  int intelligenceExp;
  int mindExp;
  
  int coins;

  AvatarModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.level = 1,
    this.exp = 0,
    this.strength = 1,
    this.intelligence = 1,
    this.mind = 1,
    this.strengthExp = 0,
    this.intelligenceExp = 0,
    this.mindExp = 0,
    this.coins = 0,
  });

  // Convert from Firestore Document
  factory AvatarModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AvatarModel(
      id: documentId,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? 'Pet',
      species: data['species'] ?? 'Unknown',
      level: data['level'] ?? 1,
      exp: data['exp'] ?? 0,
      strength: data['strength'] ?? (data['stamina'] ?? 1), // Migration: Use stamina as fallback or default 1
      intelligence: data['intelligence'] ?? (data['focus'] ?? 1), // Migration: Focus -> Intelligence
      mind: data['mind'] ?? 1,
      strengthExp: data['strength_exp'] ?? 0,
      intelligenceExp: data['intelligence_exp'] ?? 0,
      mindExp: data['mind_exp'] ?? 0,
      coins: data['coins'] ?? 0,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'species': species,
      'level': level,
      'exp': exp,
      'strength': strength,
      'intelligence': intelligence,
      'mind': mind,
      'strength_exp': strengthExp,
      'intelligence_exp': intelligenceExp,
      'mind_exp': mindExp,
      'coins': coins,
    };
  }
}
