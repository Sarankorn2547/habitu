class AvatarModel {
  String id;
  String userId;
  String name;
  String species;
  int level;
  int exp;
  int strength;
  int stamina; // ใช้สำหรับ Workout
  int focus; // ใช้สำหรับ Work/Study
  int coins;

  AvatarModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.level = 1,
    this.exp = 0,
    this.strength = 1,
    this.stamina = 1,
    this.focus = 1,
    this.coins = 0,
  });

  // แปลงจาก Firestore Document เป็น Object
  factory AvatarModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AvatarModel(
      id: documentId,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? 'Pet',
      species: data['species'] ?? 'Unknown',
      level: data['level'] ?? 1,
      exp: data['exp'] ?? 0,
      strength: data['strength'] ?? 1,
      stamina: data['stamina'] ?? 1,
      focus: data['focus'] ?? 1,
      coins: data['coins'] ?? 0,
    );
  }

  // แปลง Object เป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'species': species,
      'level': level,
      'exp': exp,
      'strength': strength,
      'stamina': stamina,
      'focus': focus,
      'coins': coins,
    };
  }
}
