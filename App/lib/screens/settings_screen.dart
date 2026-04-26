import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    // ดึงระดับเสียงปัจจุบันจากเครื่องเล่นมาแสดงที่ Slider
    _volume = themePlayer.volume;
  }

  void _showChangeUsernameDialog() {
    TextEditingController controller = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Username"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new username"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _auth.updateUsername(controller.text);
                await FirebaseAuth.instance.currentUser?.reload();
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Username updated.")));
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await _auth.updatePassword(controller.text);
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Password updated")));
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed to update password. You may need to relogin.",
                        ),
                      ),
                    );
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
        content: Text(
          "Are you sure you want to delete all your application data? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                DatabaseService db = DatabaseService(uid: uid);
                await db.deleteAllUserData();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("All data deleted")));
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
        content: Text(
          "Are you sure you want to delete your account permanently? All data will be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed to delete account. You may need to relogin.",
                        ),
                      ),
                    );
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
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName;
    final email = user?.email ?? 'No Email';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.person, size: 40, color: Colors.orange),
                ),
                SizedBox(height: 16),
                if (displayName != null && displayName.isNotEmpty) ...[
                  Text(
                    displayName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ] else ...[
                  Text(
                    email,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Image.asset('assets/icons/ChangeUsername.png'),
            title: Text("Change Username"),
            onTap: _showChangeUsernameDialog,
          ),
          ListTile(
            leading: Image.asset('assets/icons/ChangePassword.png'),
            title: Text("Change Password"),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            title: Text("Background Music Volume"),
            leading: Image.asset('assets/icons/BackgroundMusic.png'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.volume_down, size: 20, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    activeColor: Colors.orange,
                    label: "${(_volume * 100).toInt()}%",
                    onChanged: (val) {
                      setState(() {
                        _volume = val;
                        themePlayer.setVolume(val);
                      });
                    },
                  ),
                ),
                Icon(Icons.volume_up, size: 20, color: Colors.grey),
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Image.asset('assets/icons/DeleteAllData.png'),
            title: Text(
              "Delete All Data",
              style: TextStyle(color: Colors.orange),
            ),
            onTap: _showDeleteDataDialog,
          ),
          ListTile(
            leading: Image.asset('assets/icons/DeleteAccount.png'),
            title: Text("Delete Account", style: TextStyle(color: Colors.red)),
            onTap: _showDeleteAccountDialog,
          ),
          Divider(),
          ListTile(
            leading: Image.asset('assets/icons/Logout.png'),
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
