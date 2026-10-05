import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // সেশনের জন্য ইম্পোর্ট
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart'; // ড্যাশবোর্ড স্ক্রিন ইম্পোর্ট
import 'package:firebase_core/firebase_core.dart'; // Firebase import
import 'firebase_options.dart'; // Firebase options import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👉 ফায়ারবেস ইনিশিয়ালাইজেশন (এটি যোগ করা হয়েছে)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ব্যাকগ্রাউন্ড নোটিফিকেশন সার্ভিস ইনিশিয়ালাইজ করা
  await NotificationService.init();

  // রানটাইমে নোটিফিকেশন পারমিশন চাওয়া
  await NotificationService.requestNotificationPermission();

  // 🔑 শেয়ার্ড প্রেফারেন্সেস থেকে আগের লগইন স্ট্যাটাস চেক (V1 এর লজিক)
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String userEmail = prefs.getString('userEmail') ?? '';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(isLoggedIn: isLoggedIn, userEmail: userEmail),
    ),
  );
}

// 🌓 থিম ম্যানেজ করার জন্য প্রোভাইডার ক্লাস
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userEmail;

  const MyApp({super.key, required this.isLoggedIn, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Smart Health Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
      ),
      // 👉 সেশন ট্র্যাকিং লজিক
      home: isLoggedIn
          ? DashboardScreen(userEmail: userEmail)
          : const LoginScreen(),
    );
  }
}