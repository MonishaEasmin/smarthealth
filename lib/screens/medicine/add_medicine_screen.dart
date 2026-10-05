import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medication_model.dart';
import '../../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final String userEmail;
  const AddMedicineScreen({super.key, required this.userEmail});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _nameController = TextEditingController();
  final _pillCountController = TextEditingController(text: "1");

  String _selectedType = 'Tablet';
  String _selectedDoseUnit = 'Table';
  String _selectedFrequency = '1 time, Daily';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 10));

  List<String> _mySelectedTimesList = ['12:08 AM'];
  TimeOfDay _notificationTime = const TimeOfDay(hour: 0, minute: 8);

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _notificationTime = picked;
        _mySelectedTimesList.clear();
        _mySelectedTimesList.add(picked.format(context));
      });
    }
  }

  void _saveMedication() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter medication name')),
      );
      return;
    }

    // প্রোগ্রেস বা লোডিং ডায়ালগ দেখানো
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      MedicationModel newMedicine = MedicationModel(
        name: _nameController.text,
        type: _selectedType,
        startDate: "${_startDate.year}-${_startDate.month}-${_startDate.day}",
        endDate: "${_endDate.year}-${_endDate.month}-${_endDate.day}",
        pillCount: int.tryParse(_pillCountController.text) ?? 1,
        doseUnit: _selectedDoseUnit,
        frequency: _selectedFrequency,
        scheduleTimes: _mySelectedTimesList,
      );

      Map<String, dynamic> medicineMap = Map<String, dynamic>.from(newMedicine.toMap());
      medicineMap['userEmail'] = widget.userEmail;
      medicineMap['status'] = 'Ongoing';

      // ১. Cloud Firestore-এ ডেটা সেভ করা
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('medicines')
          .add(medicineMap);

      int notificationId = docRef.id.hashCode.abs();

      // ২. নোটিফিকেশন শিডিউল করা
      try {
        await NotificationService.scheduleNotification(
          id: notificationId,
          title: 'Time to take your medicine! 💊',
          body: 'Please take ${_nameController.text} (${_pillCountController.text} $_selectedDoseUnit) now.',
          hour: _notificationTime.hour,
          minute: _notificationTime.minute,
        );
      } catch (notifError) {
        debugPrint("Notification Error: $notifError");
      }

      // ডায়ালগ এবং পেজ বন্ধ করা
      if (!mounted) return;
      Navigator.pop(context); // CircularProgressIndicator বন্ধ করবে

      if (!mounted) return;
      Navigator.pop(context); // আগের পেজে ফিরে যাবে

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication added & Reminder Scheduled!')),
      );
    } catch (e) {
      debugPrint("Error while saving medication: $e");

      if (!mounted) return;
      Navigator.pop(context); // ডায়ালগ বন্ধ করবে

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Add Medication', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pill's Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Medication Name',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Medication Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: ['Tablet', 'Capsule', 'Pessary', 'Syrup'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 20),

            const Text("Amount & Unit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pillCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDoseUnit,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ['Table', 'Capsule', 'Pessary', 'Pill', 'ml'].map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDoseUnit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text("Frequency", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: ['1 time, Daily', '2 times, Daily', '3 times, Daily', 'Every Week'].map((freq) {
                return DropdownMenuItem(value: freq, child: Text(freq));
              }).toList(),
              onChanged: (val) => setState(() => _selectedFrequency = val!),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Start Date", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text("${_startDate.day}/${_startDate.month}/${_startDate.year}", style: const TextStyle(fontSize: 14)),
                        trailing: const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
                        onTap: () => _selectDate(context, true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("End Date", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text("${_endDate.day}/${_endDate.month}/${_endDate.year}", style: const TextStyle(fontSize: 14)),
                        trailing: const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
                        onTap: () => _selectDate(context, false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text("Set Schedule Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text("Selected Time: ${_mySelectedTimesList.join(', ')}", style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.access_time, color: Colors.blue, size: 22),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveMedication,
                child: const Text('Done', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}