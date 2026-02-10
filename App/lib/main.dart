import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitu Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Habitu Firebase Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void addHabit() {
    FirebaseFirestore.instance
        .collection('habits')
        .add({
          'name': 'อ่านหนังสือ',
          'status': 'incomplete',
          'timestamp': FieldValue.serverTimestamp(),
          'count': _counter, // ลองเก็บเลข Counter ไปด้วยก็ได้ครับ
        })
        .then((value) => print("บันทึกข้อมูลสำเร็จ! ID: ${value.id}"))
        .catchError((error) => print("เกิดข้อผิดพลาด: $error"));
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    addHabit(); // กดปุ่มแล้วส่งข้อมูลทันที
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('กดปุ่มเพื่อส่งข้อมูลไป Firebase:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment & Send',
        child: const Icon(Icons.cloud_upload), // เปลี่ยนไอคอนให้ดูสื่อถึง Cloud
      ),
    );
  }
}
