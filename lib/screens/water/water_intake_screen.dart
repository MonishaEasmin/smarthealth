import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaterIntakeScreen extends StatefulWidget {
  final String userEmail;
  const WaterIntakeScreen({super.key, required this.userEmail});

  @override
  State<WaterIntakeScreen> createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  int _dailyGoal = 2000;
  int _currentIntake = 0;
  bool _isLoading = true;

  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWaterData();
  }

  Future<void> _fetchWaterData() async {
    setState(() => _isLoading = true);
    try {
      String todayDate = DateTime.now().toIso8601String().split('T')[0];

      var querySnapshot = await FirebaseFirestore.instance
          .collection('water_intake')
          .where('email', isEqualTo: widget.userEmail)
          .where('date', isEqualTo: todayDate)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data();
        setState(() {
          _currentIntake = data['amount'] ?? 0;
          _dailyGoal = data['dailyGoal'] ?? 2000;
        });
      } else {
        await FirebaseFirestore.instance.collection('water_intake').add({
          'email': widget.userEmail,
          'date': todayDate,
          'amount': 0,
          'dailyGoal': 2000,
        });
      }
    } catch (e) {
      debugPrint("Error fetching water data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateWaterIntake(int addedAmount) async {
    setState(() {
      _currentIntake += addedAmount;
      if (_currentIntake < 0) _currentIntake = 0;
    });

    try {
      String todayDate = DateTime.now().toIso8601String().split('T')[0];
      var querySnapshot = await FirebaseFirestore.instance
          .collection('water_intake')
          .where('email', isEqualTo: widget.userEmail)
          .where('date', isEqualTo: todayDate)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('water_intake').doc(docId).update({
          'amount': _currentIntake,
        });
      }
    } catch (e) {
      debugPrint("Error updating water intake: $e");
    }
  }

  void _showGoalDialog() {
    _goalController.text = _dailyGoal.toString();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Daily Water Goal'),
        content: TextField(
          controller: _goalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Goal in ml (e.g., 3000)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              int newGoal = int.tryParse(_goalController.text) ?? 2000;
              setState(() {
                _dailyGoal = newGoal;
              });

              String todayDate = DateTime.now().toIso8601String().split('T')[0];
              var querySnapshot = await FirebaseFirestore.instance
                  .collection('water_intake')
                  .where('email', isEqualTo: widget.userEmail)
                  .where('date', isEqualTo: todayDate)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                String docId = querySnapshot.docs.first.id;
                await FirebaseFirestore.instance.collection('water_intake').doc(docId).update({
                  'dailyGoal': newGoal,
                });
              }

              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Water Intake Tracker'), backgroundColor: Colors.blue),
        body: const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    double progress = (_currentIntake / _dailyGoal).clamp(0.0, 1.0);
    int remaining = _dailyGoal - _currentIntake;

    String complimentMessage = "";
    if (_currentIntake >= _dailyGoal) {
      complimentMessage = "🎉 Awesome! You've reached your daily water goal!";
    } else if (remaining <= 500) {
      complientMessageHelp(remaining); // placeholder
      complimentMessage = "🔥 Almost there! Just $remaining ml more to go!";
    } else {
      complimentMessage = "💧 Stay hydrated! Drink $remaining ml more today.";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake Tracker', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showGoalDialog,
            tooltip: 'Set Goal',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.blue.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, size: 40, color: Colors.blue),
                    const SizedBox(height: 5),
                    Text(
                      "$_currentIntake ml",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    Text(
                      "Goal: $_dailyGoal ml",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                complimentMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
              ),
            ),
            const SizedBox(height: 40),
            const Text('Add Water Intake', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () => _updateWaterIntake(250),
                  icon: const Icon(Icons.add),
                  label: const Text('+250 ml (Glass)'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: () => _updateWaterIntake(500),
                  icon: const Icon(Icons.add),
                  label: const Text('+500 ml (Bottle)'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: () => _updateWaterIntake(-250),
              icon: const Icon(Icons.remove, color: Colors.red),
              label: const Text('Undo / Remove 250 ml', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void complientMessageHelp(int rem) {}
}