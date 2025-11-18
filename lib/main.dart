import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/reports_screen.dart';
import 'services/auth_service.dart'; 

void main() async {
  // 1. ضمان تهيئة بيئة فلاتر قبل استخدام التخزين
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. فحص التوكن المحفوظ
  final token = await AuthService.getToken();
  final isLoggedIn = token != null;

  // 3. تشغيل التطبيق وتحديد شاشة البداية
  runApp(AttendanceApp(startScreen: isLoggedIn ? const HomeScreen() : const LoginScreen()));
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
        fontFamily: 'Segoe UI', // خط مناسب للويندوز
      ),
      home: startScreen, // يبدأ بالشاشة المناسبة (Login أو Home)
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  // --- دالة تسجيل الخروج ---
  void _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      // الانتقال لشاشة تسجيل الدخول وحذف كل الصفحات السابقة
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
            // زر تسجيل الخروج
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
            
            // زر التسجيل
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

            // زر التقارير
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
          ],
        ),
      ),
    );
  }
}