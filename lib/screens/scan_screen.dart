import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart'; // تأكد من استدعاء ملف الخدمة

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
      // 2. استخدام الرابط من AuthService
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
          'teacher_id': 1, // (يمكنك لاحقاً حفظ ID المدرس أيضاً وجلبه)
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // نجاح (أو تنبيه بأنه حاضر مسبقاً)
        _showSuccessDialog(data);
      } else {
        // خطأ (الطالب غير موجود، أو التوكن خطأ)
        _showErrorDialog(data['message'] ?? 'حدث خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('فشل الاتصال بالسيرفر. تأكد أن Laravel يعمل.\n$e');
    } finally {
      setState(() => _isLoading = false);
      _barcodeController.clear(); // مسح الحقل للاستعداد للطالب القادم
      _focusNode.requestFocus(); // إعادة التركيز فوراً
    }
  }

  // --- نوافذ التنبيه (Dialogs) ---
  void _showSuccessDialog(Map<String, dynamic> data) {
    bool isWarning = data['status'] == 'warning'; // في حالة "حاضر مسبقاً"
    
    AwesomeDialog(
      context: context,
      dialogType: isWarning ? DialogType.warning : DialogType.success,
      animType: AnimType.bottomSlide,
      title: isWarning ? 'تنبيه' : 'تم التحضير ✅',
      desc: '${data['message']}\n\n👤 الطالب: ${data['student_name']}\n🕒 الوقت: ${data['scan_time']}',
      autoHide: const Duration(seconds: 3), // يختفي تلقائياً بعد 3 ثواني
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
            // أيقونة توضيحية
            const Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            
            const Text(
              'قم بتوجيه قارئ الباركود (أو موبايلك) الآن',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // حقل إدخال الباركود (المخفي ظاهرياً للتركيز عليه)
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
              // هذه أهم خاصية: عندما يضغط البرنامج "Enter"
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