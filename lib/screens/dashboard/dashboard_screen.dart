import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medication_model.dart';
import '../../widgets/custom_drawer.dart';
import '../medicine/add_medicine_screen.dart';
import '../prescription/prescription_screen.dart';
import '../reports/report_screen.dart';
import '../water/water_intake_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  const DashboardScreen({super.key, required this.userEmail});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _lowStockCount = 0;
  List<MedicationModel> _allMedications = [];
  bool _isLoading = true;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ☁️ ক্লাউড ফায়ারস্টোর থেকে ইউজারের মেডিসিন ডাটা লোড করার মেথড
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('userEmail', isEqualTo: widget.userEmail)
          .get();

      List<MedicationModel> loadedMeds = [];
      int lowStockCount = 0;

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        // ফায়ারবেসের ডকুমেন্ট আইডিটি মডেলে আইডি হিসেবে সেট করা
        data['id'] = doc.id.hashCode; // অথবা স্ট্রিং আইডি হ্যান্ডেল করার ব্যবস্থা
        data['docId'] = doc.id; // ফায়ারবেসের রিয়েল ডকুমেন্ট আইডি সংরক্ষণ করার জন্য

        MedicationModel med = MedicationModel.fromMap(data);
        loadedMeds.add(med);

        if (med.pillCount <= 5 && med.status == 'Ongoing') {
          lowStockCount++;
        }
      }

      if (mounted) {
        setState(() {
          _allMedications = loadedMeds;
          _lowStockCount = lowStockCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  // 💊 ওষুধ Taken/Missed স্ট্যাটাস ফায়ারবেসে আপডেট করার মেথড
  void _logMedicationStatus(MedicationModel med, String timeSlot, String status) async {
    final todayStr = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    try {
      // হিস্ট্রি লগ ফায়ারস্টোরে সেভ করা
      await FirebaseFirestore.instance.collection('medication_logs').add({
        'userEmail': widget.userEmail,
        'medicationName': med.name,
        'dateTime': "$todayStr $timeSlot",
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ইউজার ওষুধ খেয়ে থাকলে স্টক আপডেট করা
      if (status == 'Taken' && med.pillCount > 0) {
        int newStock = med.pillCount - 1;
        String newStatus = newStock == 0 ? 'Completed' : 'Ongoing';

        // যদি মডেলে ফায়ারবেস ডকুমেন্ট আইডি রাখা থাকে
        // এখানে ধরে নেওয়া হচ্ছে কুয়েরি করার সময় doc.id ট্র্যাক করা হয়েছে
        // সহজ সমাধানের জন্য আমরা ফিল্টার করে ডকুমেন্ট আপডেট করছি
        final querySnapshot = await FirebaseFirestore.instance
            .collection('medications')
            .where('userEmail', isEqualTo: widget.userEmail)
            .where('name', isEqualTo: med.name)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          String docId = querySnapshot.docs.first.id;
          await FirebaseFirestore.instance.collection('medications').doc(docId).update({
            'pillCount': newStock,
            'status': newStatus,
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${med.name} marked as $status!')),
      );
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  // 🗑️ ওষুধ ডিলিট করার মেথড
  void _deleteMedicationDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete $name and its schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('medications')
                    .where('userEmail', isEqualTo: widget.userEmail)
                    .where('name', isEqualTo: name)
                    .get();

                for (var doc in querySnapshot.docs) {
                  await doc.reference.delete();
                }

                _loadAllData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e')),
                  );
                }
              }
            },
            child: const Text('Delete ', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Today\'s Schedule' : (_currentIndex == 2 ? 'All Medicines' : 'Smart Health Assistant'),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: CustomDrawer(userEmail: widget.userEmail),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _loadAllData();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Medicines'),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_currentIndex == 0) return _buildTodayTimelineView();
    if (_currentIndex == 2) return _buildAllMedicinesListView();
    return _buildGridDashboardView();
  }

  // ================= 📅 ১. TODAY TIMELINE VIEW =================
  Widget _buildTodayTimelineView() {
    List<Map<String, dynamic>> todaySlots = [];
    for (var med in _allMedications) {
      if (med.status == 'Ongoing') {
        for (String time in med.scheduleTimes) {
          todaySlots.add({'medicine': med, 'time': time});
        }
      }
    }

    if (todaySlots.isEmpty) {
      return const Center(child: Text('No medicines scheduled for today.'));
    }

    todaySlots.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: todaySlots.length,
      itemBuilder: (context, index) {
        final slot = todaySlots[index];
        final MedicationModel med = slot['medicine'];
        final String time = slot['time'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _deleteMedicationDialog(med.name),
                    )
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: const Icon(Icons.medication, color: Colors.teal),
                  ),
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Stock Remaining: ${med.pillCount} ${med.doseUnit}'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Missed'),
                      onPressed: () => _logMedicationStatus(med, time, 'Missed'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Taken'),
                      onPressed: () => _logMedicationStatus(med, time, 'Taken'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllMedicinesListView() {
    if (_allMedications.isEmpty) return const Center(child: Text('No medicines added yet.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _allMedications.length,
      itemBuilder: (context, index) {
        final medicine = _allMedications[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.medication, color: Colors.teal, size: 36),
            title: Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text("Dose: ${medicine.pillCount} | Freq: ${medicine.frequency}"),
            trailing: Text(medicine.status, style: TextStyle(color: medicine.status == 'Ongoing' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildGridDashboardView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(icon: Icons.local_hospital_rounded, label: 'Add Medicine', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMedicineScreen(userEmail: widget.userEmail))).then((_) => _loadAllData())),
          _buildMenuCard(icon: Icons.access_time_filled_rounded, label: 'Reminder', onTap: () => setState(() => _currentIndex = 0)),
          _buildMenuCard(icon: Icons.bar_chart_rounded, label: 'Reports', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(userEmail: widget.userEmail)))),
          _buildMenuCard(icon: Icons.folder_rounded, label: 'Prescription', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrescriptionScreen(userEmail: widget.userEmail)))),
          _buildMenuCard(icon: Icons.water_drop,label: 'Water Intake',onTap: () => Navigator.push(context,MaterialPageRoute(builder: (_) => WaterIntakeScreen(userEmail: widget.userEmail),),),),
          _buildMenuCard(icon: Icons.history_rounded, label: 'History', onTap: () => setState(() => _currentIndex = 0)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: Colors.blue.shade600), const SizedBox(height: 10), Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildStockMenuCard({required IconData icon, required String label, required int lowStockAlertCount, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: lowStockAlertCount > 0 ? Border.all(color: Colors.red.shade300, width: 1.5) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: Colors.blue.shade600), const SizedBox(height: 10), Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))]),
          ),
          if (lowStockAlertCount > 0) Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text('$lowStockAlertCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}