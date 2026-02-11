import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/avatar_model.dart'; // ต้องมีไฟล์ model นี้ด้วย (ดูข้อ 2)

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  // Collection Reference
  final CollectionReference avatarCollection = FirebaseFirestore.instance
      .collection('avatars');
  final CollectionReference exerciseCollection = FirebaseFirestore.instance
      .collection('exercise_logs');

  // ดึงข้อมูล Avatar แบบ Realtime (Stream)
  Stream<AvatarModel?> get myAvatar {
    return avatarCollection
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          // แปลงข้อมูลจาก Firestore เป็น Object AvatarModel
          return AvatarModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>,
            snapshot.docs.first.id,
          );
        });
  }

  // สร้าง Avatar เริ่มต้น (สำหรับ User ใหม่)
  Future<void> createInitialAvatar(String name) async {
    await avatarCollection.add({
      'user_id': uid,
      'name': name,
      'species': 'Cat',
      'level': 1,
      'exp': 0,
      'strength': 1,
      'stamina': 1,
      'focus': 1,
      'coins': 0,
    });
  }

  // บันทึกการออกกำลังกาย และ อัปเดต Stat
  Future<void> logExerciseAndReward({
    required String type,
    int? duration,
    int? sets,
    int? reps,
    required String avatarId,
    required int currentExp,
    required int currentCoin,
    required int currentStrength,
  }) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 1. สร้าง Log การออกกำลังกาย
    DocumentReference logRef = exerciseCollection.doc();
    batch.set(logRef, {
      'user_id': uid,
      'exercise_type': type,
      'duration_min': duration ?? 0,
      'sets': sets ?? 0,
      'reps': reps ?? 0,
      'exp_gained': 10,
      'logged_at': FieldValue.serverTimestamp(),
    });

    // 2. อัปเดตค่าพลังของสัตว์เลี้ยง
    DocumentReference avatarRef = avatarCollection.doc(avatarId);
    batch.update(avatarRef, {
      'exp': currentExp + 10,
      'coins': currentCoin + 5,
      'strength': currentStrength + 1,
    });

    await batch.commit();
  }
}
