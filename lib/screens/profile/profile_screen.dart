import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;
  const ProfileScreen({super.key, required this.userEmail});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  double _bmi = 0.0;
  String _bmiStatus = "N/A";
  bool _isLoading = true;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // Firebase theke user data ana
  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var docData = querySnapshot.docs.first.data();
        setState(() {
          _userData = docData;
          _nameCtrl.text = docData['name']?.toString() ?? '';
          _ageCtrl.text = docData['age']?.toString() ?? '';
          _heightCtrl.text = docData['height']?.toString() ?? '';
          _weightCtrl.text = docData['weight']?.toString() ?? '';
        });
        _calculateBmiLocally();
      } else {
        // Jodi user document na thake tahole ekta create kore nibe
        await FirebaseFirestore.instance.collection('users').add({
          'email': widget.userEmail,
          'name': '',
          'age': '',
          'height': '',
          'weight': '',
          'profileImage': '',
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // লাইভ BMI ক্যালকুলেশন
  void _calculateBmiLocally() {
    double heightInCm = double.tryParse(_heightCtrl.text) ?? 0.0;
    double weightInKg = double.tryParse(_weightCtrl.text) ?? 0.0;

    setState(() {
      if (heightInCm > 0 && weightInKg > 0) {
        double heightInMeters = heightInCm / 100;
        _bmi = weightInKg / (heightInMeters * heightInMeters);
      } else {
        _bmi = 0.0;
      }

      if (_bmi > 0) {
        if (_bmi < 18.5) {
          _bmiStatus = "Underweight";
        } else if (_bmi < 24.9) {
          _bmiStatus = "Normal";
        } else {
          _bmiStatus = "Overweight";
        }
      } else {
        _bmiStatus = "N/A";
      }
    });
  }

  // গ্যালারি থেকে ছবি সিলেクト করে ফায়ারস্টোরে পাথ আপডেট করা
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (image != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.userEmail)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          String docId = querySnapshot.docs.first.id;
          await FirebaseFirestore.instance.collection('users').doc(docId).update({
            'profileImage': image.path,
          });
          await _fetchUserData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated successfully!')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // প্রোফাইল ডিটেইলস ফায়ারস্টোরে আপডেট করা
  Future<void> _updateProfileData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'name': _nameCtrl.text.trim(),
          'age': _ageCtrl.text.trim(),
          'height': _heightCtrl.text.trim(),
          'weight': _weightCtrl.text.trim(),
        });

        await _fetchUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile & Edit', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    String? profileImagePath = _userData?['profileImage'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Edit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickProfileImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: (profileImagePath != null && profileImagePath.isNotEmpty && File(profileImagePath).existsSync())
                        ? FileImage(File(profileImagePath)) as ImageProvider
                        : null,
                    child: (profileImagePath == null || profileImagePath.isEmpty || !File(profileImagePath).existsSync())
                        ? const Icon(Icons.person, size: 55, color: Colors.teal)
                        : null,
                  ),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to change profile picture', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 30),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              onChanged: (val) => _calculateBmiLocally(),
              decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              onChanged: (val) => _calculateBmiLocally(),
              decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.teal,
              ),
              onPressed: _updateProfileData,
              child: const Text('Save Profile Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 40),

            Card(
              elevation: 2,
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('BMI Score', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(_bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 22, color: Colors.teal, fontWeight: FontWeight.bold))
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(_bmiStatus, style: const TextStyle(fontSize: 22, color: Colors.teal, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}