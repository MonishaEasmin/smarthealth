import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medication_model.dart';

class StockScreen extends StatefulWidget {
  final String userEmail;
  const StockScreen({super.key, required this.userEmail});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<MedicationModel> _medicationStockList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  void _loadStockData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // ফায়ারবেস ফায়ারস্টোর থেকে ইউজারের ইমেইল অনুযায়ী মেডিসিন স্টক ফেচ করা
      final querySnapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('userEmail', isEqualTo: widget.userEmail)
          .get();

      List<MedicationModel> loadedStock = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id.hashCode; // ইউনিক আইডি ম্যাপ করার জন্য
        MedicationModel item = MedicationModel.fromMap(data);
        loadedStock.add(item);
      }

      if (mounted) {
        setState(() {
          _medicationStockList = loadedStock;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stock: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Medicine Stock Status', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _medicationStockList.isEmpty
          ? const Center(
        child: Text(
          'No medicine stock available.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicationStockList.length,
        itemBuilder: (context, index) {
          final item = _medicationStockList[index];
          bool isCompleted = item.status == 'Completed';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isCompleted ? Colors.grey.shade100 : Colors.teal.shade50,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isCompleted ? Colors.grey : Colors.teal,
                child: const Icon(Icons.medication, color: Colors.white),
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text("Type: ${item.type} | Dose: ${item.pillCount} ${item.doseUnit}"),
                  Text("Duration: ${item.startDate} to ${item.endDate}"),
                  const SizedBox(height: 4),
                  Text(
                    "Status: ${item.status}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.grey : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}