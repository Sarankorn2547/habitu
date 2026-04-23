import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Imports ไฟล์ต่างๆ ในโปรเจกต์ ---
import 'firebase_options.dart'; // สำคัญ: ต้อง import เพื่อให้ใช้ DefaultFirebaseOptions ได้
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:audioplayers/audioplayers.dart';

final AudioPlayer themePlayer = AudioPlayer();

void main() async {
  // 1. รอให้ Native Code โหลดเสร็จก่อน
  WidgetsFlutterBinding.ensureInitialized();

  // 2. เริ่มต้น Firebase ด้วย Options ที่ได้จาก FlutterFire CLI
  // (แก้ปัญหาเรื่องหา google-services.json ไม่เจอ หรือ setup ผิด platform)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
  await themePlayer.setReleaseMode(ReleaseMode.loop);
  await themePlayer.setVolume(0.3);
  await AudioPlayer.global.setAudioContext(AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  ));
  await effectPlayer.setPlayerMode(PlayerMode.lowLatency);
  await effectPlayer.setSource(AssetSource('audio/click.mp3'));
  await effectPlayer.setVolume(0.5);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _audioStarted = false;
  bool _wasPlayingBeforePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tryPlayAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      if (themePlayer.state == PlayerState.playing) {
        _wasPlayingBeforePause = true;
        themePlayer.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause) {
        themePlayer.resume();
        _wasPlayingBeforePause = false;
      }
    }
  }

  void _tryPlayAudio() async {
    try {
      if (themePlayer.state != PlayerState.playing) {
        await themePlayer.play(AssetSource('audio/themeSong.mp3'));
        _audioStarted = true;
      }
    } catch (e) {
      // Autoplay might be blocked by the browser.
    }
  }

  void _handleUserInteraction() {
    if (!_audioStarted) {
      _tryPlayAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handleUserInteraction(),
      behavior: HitTestBehavior.translucent,
      child: MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
          StreamProvider<User?>(
            create: (context) => context.read<AuthService>().user,
            initialData: null,
            catchError: (_, err) => null,
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Habit U',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              brightness: Brightness.light,
            ),
            fontFamily: 'monospace',
          ),
          home: AuthenticationWrapper(),
        ),
      ),
    );
  }
}

// Widget ตัวตัดสินใจว่าจะพาไปหน้าไหน (Gatekeeper)
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

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

final AudioPlayer effectPlayer = AudioPlayer();

void playClickSound() {
  // ไม่ต้องใช้ await เพราะเราต้องการให้เสียงดังทันทีที่กด ไม่ต้องรอโหลดเสร็จ
  effectPlayer.play(AssetSource('audio/click.mp3'), volume: 0.5);
}
