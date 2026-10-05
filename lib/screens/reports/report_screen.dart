import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  final String userEmail;
  const ReportScreen({super.key, required this.userEmail});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _takenCount = 0;
  int _missedCount = 0;
  List<Map<String, dynamic>> _historyLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  void _fetchReportData() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('medication_logs')
          .where('userEmail', isEqualTo: widget.userEmail)
          .get();

      List<Map<String, dynamic>> logs = [];
      int taken = 0;
      int missed = 0;

      for (var doc in querySnapshot.docs) {
        var log = doc.data();
        logs.add(log);
        if (log['status'] == 'Taken') {
          taken++;
        } else if (log['status'] == 'Missed') {
          missed++;
        }
      }

      setState(() {
        _historyLogs = logs;
        _takenCount = taken;
        _missedCount = missed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching reports: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = _takenCount + _missedCount;
    double performanceRate = total > 0 ? (_takenCount / total) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Weekly Analytics Report', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      "Adherence Performance",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${performanceRate.toStringAsFixed(1)}%",
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: performanceRate >= 70 ? Colors.green : Colors.orange),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatSummary(Icons.check_circle, "Taken", "$_takenCount", Colors.green),
                        _buildStatSummary(Icons.cancel, "Missed", "$_missedCount", Colors.red),
                        _buildStatSummary(Icons.assessment, "Total Logs", "$total", Colors.blue),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Medication Intake History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _historyLogs.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: Text('No historical log available yet.', style: TextStyle(color: Colors.grey)),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyLogs.length,
              itemBuilder: (context, index) {
                final log = _historyLogs[index];
                bool isTaken = log['status'] == 'Taken';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTaken ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(isTaken ? Icons.check : Icons.close, color: isTaken ? Colors.green : Colors.red),
                    ),
                    title: Text(
                      log['medicationName'] ?? 'Medicine',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text("Scheduled: ${log['dateTime'] ?? ''}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTaken ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log['status'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSummary(IconData icon, String label, String count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}