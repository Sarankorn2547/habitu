import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // import เพื่อใช้ UserCredential type (ถ้าจำเป็น)
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  // สถานะ: true = กำลัง Login, false = กำลังสมัครสมาชิก
  bool _isLogin = true;
  // สถานะ: กำลังโหลดข้อมูลจาก Firebase หรือไม่
  bool _isLoading = false;

  // ฟังก์ชันสำหรับกดปุ่ม Submit
  Future<void> _submitForm() async {
    // 1. ตรวจสอบว่ากรอกข้อมูลครบไหม
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in email and password")),
      );
      return;
    }

    // 2. เริ่มโหลด (หมุนๆ)
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // --- โหมด Login ---
        final user = await _auth.signIn(
          _emailController.text.trim(),
          _passController.text.trim(),
        );
        if (user == null) {
          throw Exception("Login failed. Check your email/password.");
        }
      } else {
        // --- โหมด Register ---
        final user = await _auth.signUp(
          _emailController.text.trim(),
          _passController.text.trim(),
        );
        if (user == null) {
          throw Exception("Registration failed. Please try again.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Account Created! Logging in...")),
          );
        }
      }
      // ถ้าสำเร็จ Stream ใน main.dart จะพาไปหน้า Home เอง
    } catch (e) {
      // ถ้ามี Error ให้โชว์ SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      // 3. หยุดโหลด (ไม่ว่าจะสำเร็จหรือล้มเหลว)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ Center และ SingleChildScrollView เพื่อไม่ให้คีย์บอร์ดบังช่องกรอก
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo หรือ Icon
              Icon(Icons.pets, size: 80, color: Colors.orange),
              SizedBox(height: 20),

              // Title
              Text(
                _isLogin ? "Welcome Back!" : "Create Account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),

              // Email Input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),

              // Password Input
              TextField(
                controller: _passController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 25),

              // Main Button (Login / Register)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : _submitForm, // ถ้าโหลดอยู่ ห้ามกดซ้ำ
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        ) // โชว์ตัวหมุนถ้าโหลด
                      : Text(
                          _isLogin ? "Login" : "Register",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              SizedBox(height: 15),

              // Toggle Button (สลับโหมด)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin; // สลับค่า true <-> false
                  });
                },
                child: Text(
                  _isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
