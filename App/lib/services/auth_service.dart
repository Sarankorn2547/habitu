import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream เพื่อเช็คสถานะ Login
  Stream<User?> get user => _auth.authStateChanges();

  // Login
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is badly formatted.";
      } else if (e.code == 'invalid-credential') {
        message = "Invalid credentials. Please check your email and password.";
      }
      throw Exception(message);
    } catch (e) {
      throw Exception("An unexpected error occurred during login.");
    }
  }

  // Register
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Registration failed. Please try again.";
      if (e.code == 'weak-password') {
        message = "Password is too weak. We recommend using at least 8 characters with a mix of letters, numbers, and symbols.";
      } else if (e.code == 'email-already-in-use') {
        message = "An account already exists for that email.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is badly formatted.";
      }
      throw Exception(message);
    } catch (e) {
      throw Exception("An unexpected error occurred during registration.");
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update Username
  Future<void> updateUsername(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }
}
