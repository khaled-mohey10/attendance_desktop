import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // إعدادات التحكم
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // جعل المؤشر يركز دائماً على حقل الإدخال
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  // --- دالة إرسال الباركود للسيرفر ---
  Future<void> _submitBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    // 1. جلب التوكن المحفوظ
    final token = await AuthService.getToken();
    if (token == null) {
       _showErrorDialog("يرجى تسجيل الدخول أولاً");
       return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. استخدام الرابط الصحيح: /api/attendance/scan
      final url = Uri.parse('${AuthService.baseUrl}/attendance/scan');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token', // استخدام التوكن المحفوظ
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'barcode': barcode,
          'teacher_id': 1, // (يجب أن يكون ID المدرس من الدخول)
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessDialog(data);
      } else {
        _showErrorDialog(data['message'] ?? 'حدث خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('فشل الاتصال بالسيرفر. تأكد أن Laravel يعمل.');
    } finally {
      setState(() => _isLoading = false);
      _barcodeController.clear(); // مسح الحقل
      _focusNode.requestFocus(); // إعادة التركيز
    }
  }

  // --- نوافذ التنبيه (Dialogs) ---
  void _showSuccessDialog(Map<String, dynamic> data) {
    bool isWarning = data['status'] == 'warning';
    
    AwesomeDialog(
      context: context,
      dialogType: isWarning ? DialogType.warning : DialogType.success,
      animType: AnimType.bottomSlide,
      title: isWarning ? 'تنبيه' : 'تم التحضير ✅',
      desc: '${data['message']}\n\n👤 الطالب: ${data['student_name']}\n🕒 الوقت: ${data['scan_time']}',
      autoHide: const Duration(seconds: 3),
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      title: 'خطأ',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور (Scan Mode)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'قم بتوجيه قارئ الباركود (أو موبايلك) الآن',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _barcodeController,
              focusNode: _focusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, letterSpacing: 5),
              decoration: InputDecoration(
                hintText: 'انتظار القراءة...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: _submitBarcode,
            ),

            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            
            const SizedBox(height: 20),
            const Text(
              'نصيحة: استخدم برنامج "Barcode to PC" لربط هاتفك.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}