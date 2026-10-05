import 'dart:convert';

class MedicationModel {
  final int? id;
  final String name;          // মেডিসিনের নাম
  final String type;          // Tablet, Capsule, Pessary ইত্যাদি
  final String startDate;     // শুরুর তারিখ
  final String endDate;       // শেষের তারিখ
  final int pillCount;        // কতটি ট্যাবলেট (যেমন: 1)
  final String doseUnit;      // ডোজেস ইউনিট (যেমন: Table, Pessary, Pill)
  final String frequency;     // ফ্রিকোয়েন্সি (যেমন: 1 time, Daily)
  final List<String> scheduleTimes; // অ্যালার্ম টাইমের লিস্ট (যেমন: [9:00 AM, 3:00 PM])
  final String status;        // Ongoing নাকি Completed

  MedicationModel({
    this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.pillCount,
    required this.doseUnit,
    required this.frequency,
    required this.scheduleTimes,
    this.status = 'Ongoing',
  });

  // ডাটাবেজে সেভ করার জন্য Map-এ কনভার্ট (List-কে JSON String করা হয়েছে)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'pillCount': pillCount,
      'doseUnit': doseUnit,
      'frequency': frequency,
      'scheduleTimes': jsonEncode(scheduleTimes),
      'status': status,
    };
  }

  // ডাটাবেজ থেকে ডেটা নিয়ে মডেলে কনভার্ট
  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String,
      pillCount: map['pillCount'] as int,
      doseUnit: map['doseUnit'] as String,
      frequency: map['frequency'] as String,
      scheduleTimes: List<String>.from(jsonDecode(map['scheduleTimes'] as String)),
      status: map['status'] as String? ?? 'Ongoing',
    );
  }
}