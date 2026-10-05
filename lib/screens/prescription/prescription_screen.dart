import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionScreen extends StatefulWidget {
  final String userEmail;
  const PrescriptionScreen({super.key, required this.userEmail});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Map<String, dynamic>> _prescriptions = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  void _loadPrescriptions() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('userEmail', isEqualTo: widget.userEmail)
          .get();

      List<Map<String, dynamic>> loadedList = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        loadedList.add(data);
      }

      setState(() {
        _prescriptions = loadedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading prescriptions: $e");
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        String todayDateStr = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

        await FirebaseFirestore.instance.collection('prescriptions').add({
          'userEmail': widget.userEmail,
          'imagePath': pickedFile.path,
          'date': todayDateStr,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription added successfully!')),
          );
        }
        _loadPrescriptions();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Prescriptions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: _prescriptions.isEmpty
            ? const Center(
          child: Text('No prescriptions uploaded yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        )
            : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _prescriptions.length,
          itemBuilder: (context, index) {
            final prescription = _prescriptions[index];
            final imagePath = prescription['imagePath'] ?? '';
            final uploadDate = prescription['date'] ?? 'Unknown Date';
            final fileExists = imagePath.isNotEmpty && File(imagePath).existsSync();

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: fileExists
                          ? Image.file(File(imagePath), fit: BoxFit.cover)
                          : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "Date: $uploadDate",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showPickerOptions,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}