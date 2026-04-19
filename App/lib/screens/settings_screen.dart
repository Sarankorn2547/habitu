import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  bool _isSoundEnabled = true;

  void _showChangeUsernameDialog() {
    TextEditingController controller = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Username"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new username"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _auth.updateUsername(controller.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Username updated.")));
                  Navigator.pop(context);
                }
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Password"),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(hintText: "Enter new password"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await _auth.updatePassword(controller.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password updated")));
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update password. You may need to relogin.")));
                  }
                }
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete All Data"),
        content: Text("Are you sure you want to delete all your application data? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                DatabaseService db = DatabaseService(uid: uid);
                await db.deleteAllUserData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All data deleted")));
                  Navigator.pop(context);
                }
              }
            },
            child: Text("Delete", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to delete your account permanently? All data will be lost."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                try {
                  DatabaseService db = DatabaseService(uid: uid);
                  await db.deleteAllUserData();
                  await _auth.deleteAccount();
                  if (mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close setting screen
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete account. You may need to relogin.")));
                  }
                }
              }
            },
            child: Text("Delete Account", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Change Username"),
            onTap: _showChangeUsernameDialog,
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Change Password"),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: Icon(Icons.music_note),
            title: Text("Background Music"),
            trailing: Switch(
              value: _isSoundEnabled,
              onChanged: (val) {
                setState(() {
                  _isSoundEnabled = val;
                });
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete_sweep, color: Colors.orange),
            title: Text("Delete All Data", style: TextStyle(color: Colors.orange)),
            onTap: _showDeleteDataDialog,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text("Delete Account", style: TextStyle(color: Colors.red)),
            onTap: _showDeleteAccountDialog,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pop(context); // Close setting screen
              }
            },
          ),
        ],
      ),
    );
  }
}
