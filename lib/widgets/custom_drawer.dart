import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/medicine/add_medicine_screen.dart';
import '../screens/medicine/stock_screen.dart';
import '../screens/prescription/prescription_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/login_screen.dart';

class CustomDrawer extends StatefulWidget {
  final String userEmail;
  const CustomDrawer({super.key, required this.userEmail});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserImageFromFirebase();
  }

  // ☁️ ফায়ারস্টোর থেকে ইউজারের প্রোফাইল ছবি লোড করার মেথড
  void _loadUserImageFromFirebase() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users') // যদি কালেকশনের নাম অন্য কিছু হয় (যেমন: 'profiles'), তবে এখানে পরিবর্তন করে দিও
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data();
        // ফায়ারস্টোরে ছবির ফিল্ডের নাম যা দিয়েছ (যেমন: profileImage, imageUrl, photoUrl)
        String? imageUrl = userData['profileImage'] ?? userData['imageUrl'] ?? userData['photoUrl'];

        if (mounted && imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
        }
      }
    } catch (e) {
      print("Error loading image from Firebase: $e");
    }
  }

  // 🚪 লগআউট হ্যান্ডেল এবং সেশন ক্লিয়ার করার মেথড
  void _handleLogout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userEmail');

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // --- ড্রয়ার হেডার (ইউজার প্রোফাইল ও ইমেইল) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            color: Colors.teal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: (_profileImageUrl == null || _profileImageUrl!.isNotEmpty == false)
                      ? const Icon(Icons.person, size: 35, color: Colors.teal)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Smart Health App',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail.isEmpty ? 'user@email.com' : widget.userEmail,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- ড্রয়ারের মেনু আইটেমসমূহ ---
          ListTile(
            leading: const Icon(Icons.home, color: Colors.teal),
            title: const Text('Home Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DashboardScreen(userEmail: widget.userEmail)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box, color: Colors.teal),
            title: const Text('Add Medicine'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddMedicineScreen(userEmail: widget.userEmail)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.teal),
            title: const Text('Stock Status'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StockScreen(userEmail: widget.userEmail)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.collections, color: Colors.teal),
            title: const Text('Prescription Storage'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrescriptionScreen(userEmail: widget.userEmail)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_box, color: Colors.teal),
            title: const Text('Profile & BMI'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(userEmail: widget.userEmail)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.teal),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const Spacer(),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Logout Now', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}