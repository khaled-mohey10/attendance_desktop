import 'package:flutter/material.dart';
import 'screens/scan_screen.dart';
import 'screens/reports_screen.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الحضور الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Segoe UI', // خط مناسب للويندوز
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم - نظام الحضور'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'مرحباً بك في نظام الحضور',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20), // مسافة بين الزرين

            // --- الزر الجديد (التقارير) ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('عرض تقرير اليوم (Dashboard)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.indigo, // لون مختلف
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}