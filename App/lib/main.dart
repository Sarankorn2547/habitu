import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Imports ไฟล์ต่างๆ ในโปรเจกต์ ---
import 'firebase_options.dart'; // สำคัญ: ต้อง import เพื่อให้ใช้ DefaultFirebaseOptions ได้
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. รอให้ Native Code โหลดเสร็จก่อน
  WidgetsFlutterBinding.ensureInitialized();

  // 2. เริ่มต้น Firebase ด้วย Options ที่ได้จาก FlutterFire CLI
  // (แก้ปัญหาเรื่องหา google-services.json ไม่เจอ หรือ setup ผิด platform)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider 1: AuthService (Logic การ Login/Register)
        Provider<AuthService>(create: (_) => AuthService()),

        // Provider 2: User Stream (ฟังสถานะ Login แบบ Realtime)
        // ถ้า User Login อยู่ ค่าจะเป็น User Object
        // ถ้า User Logout ค่าจะเป็น null
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
          catchError: (_, err) => null, // ป้องกัน error จุกจิกกรณี Auth หลุด
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // ปิดป้าย Debug มุมขวาบน
        title: 'Habit U', // ชื่อแอป
        // --- Theme Setting (Material 3) ---
        theme: ThemeData(
          useMaterial3: true, // ใช้ดีไซน์แบบใหม่
          colorScheme: ColorScheme.fromSeed(
            seedColor:
                Colors.orange, // สีหลักของแอป (เข้ากับธีมสัตว์เลี้ยง/พลังงาน)
            brightness: Brightness.light,
          ),
          fontFamily: 'monospace', // (ถ้าคุณลง font แล้ว ใส่ตรงนี้ได้)
        ),

        // --- หน้าแรกที่จะแสดง ---
        home: AuthenticationWrapper(),
      ),
    );
  }
}

// Widget ตัวตัดสินใจว่าจะพาไปหน้าไหน (Gatekeeper)
class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ดึงค่า User ปัจจุบันมาจาก Provider
    final firebaseUser = Provider.of<User?>(context);

    // เช็คสถานะ
    if (firebaseUser != null) {
      // ถ้ามี User (Login แล้ว) -> ไปหน้า Home
      return HomeScreen();
    }

    // ถ้าไม่มี User (ยังไม่ Login) -> ไปหน้า Login
    return LoginScreen();
  }
}
