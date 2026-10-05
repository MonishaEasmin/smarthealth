import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔑 সেশন ক্লিয়ার করার জন্য
import '../../main.dart';
import '../auth/login_screen.dart'; // 🚪 লগইন স্ক্রিনে ব্যাক করার জন্য

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 🚪 লগআউট হ্যান্ডেল করার মেথড
  void _handleLogout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // সেশন ইন-অ্যাক্টিভ করা
    await prefs.remove('userEmail');          // ইমেইল মুছে ফেলা

    if (context.mounted) {
      // লগইন স্ক্রিনে ব্যাক করানো এবং পেছনের সব স্ক্রিন হিস্ট্রি ক্লিয়ার করা
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode Display'),
            secondary: const Icon(Icons.dark_mode),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('System Version'),
            trailing: Text('v1.0.0 (Stable)'),
          ),
          const Divider(),
          // 🚪 সেটিংসের ভেতরেও একটি লগআউট অপশন রাখা হলো
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // লগআউট করার আগে কনফার্মেশন ডায়ালগ
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // ডায়ালগ ক্লোজ করা
                        _handleLogout(context); // লগআউট মেথড কল
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}