import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/reports_screen.dart';
import 'services/auth_service.dart';
import 'screens/students_mgmt_screen.dart';
import 'screens/classes_mgmt_screen.dart'; // 👈 شاشة إدارة الفصول (تأكد من وجودها)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final token = await AuthService.getToken();
  final isLoggedIn = token != null;

  runApp(AttendanceApp(
    startScreen: isLoggedIn ? const HomeScreen() : const LoginScreen(),
  ));
}

class AttendanceApp extends StatelessWidget {
  final Widget startScreen;
  
  const AttendanceApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الحضور الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: startScreen,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  void _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم - نظام الحضور'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          )
        ],
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
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanScreen()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('بدء تسجيل الحضور (Scan)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 20),

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
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentsMgmtScreen()),
                );
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text('إدارة الطلاب (إضافة/حذف/تعديل)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------
            // زر إدارة الفصول الجديد
            // -------------------------------
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClassesMgmtScreen()),
                );
              },
              icon: const Icon(Icons.class_),
              label: const Text('إدارة الفصول'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            // -------------------------------
          ],
        ),
      ),
    );
  }
}
