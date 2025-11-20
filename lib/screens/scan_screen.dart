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
  // للعمود الأيمن (Scan Mode)
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isScanLoading = false;

  // للعمود الأيسر (Manual Mode)
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearchLoading = false;
  
  // لضمان أننا نبدأ بتركيز على الماسح
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  // --- دالة 1: تسجيل الحضور (للمسح أو اليدوي) ---
  Future<void> _submitAttendance(String barcode) async {
    if (barcode.isEmpty) return;

    setState(() => _isScanLoading = true);
    
    final token = await AuthService.getToken();
    if (token == null) return _showErrorDialog("يرجى تسجيل الدخول أولاً");

    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/attendance/scan'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': barcode,
          'teacher_id': 1, // نفترض أن ID المدرس 1 هو المسجل
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessDialog(data);
      } else {
        _showErrorDialog(data['message'] ?? 'حدث خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('فشل الاتصال بالسيرفر.');
    } finally {
      setState(() => _isScanLoading = false);
      _barcodeController.clear(); 
      _focusNode.requestFocus(); 
    }
  }

  // --- دالة 2: البحث اليدوي عن الطلاب (API الجديدة) ---
  Future<void> _searchStudents(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isSearchLoading = true);
    
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      // 👈 استخدام API البحث الجديدة (GET /api/students?search=...)
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/students?search=$query'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = jsonDecode(response.body)['students'];
        });
      } else {
         // لا شيء يحدث إذا فشل البحث
      }
    } catch (e) {
      // لا شيء يحدث إذا فشل البحث
    } finally {
      setState(() => _isSearchLoading = false);
    }
  }

  // --- دوال التنبيه ---
  void _showSuccessDialog(Map<String, dynamic> data) {
    bool isWarning = data['status'] == 'warning';
    AwesomeDialog(
      context: context,
      dialogType: isWarning ? DialogType.warning : DialogType.success,
      title: isWarning ? 'تنبيه' : 'تم التحضير ✅',
      desc: 'الطالب: ${data['student_name']}\nالوقت: ${data['scan_time']}',
      autoHide: const Duration(seconds: 3),
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'خطأ',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور الشامل (مسح / يدوي)'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Row( // 👈 استخدام Row للتقسيم الاحترافي
        children: [
          // 👈 العمود الأيمن: ماسح الباركود (الشاشة الأساسية)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(40.0),
              color: Colors.grey[50],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 120, color: Colors.blueGrey),
                  const SizedBox(height: 30),
                  const Text('وضع الماسح السريع', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),

                  TextField(
                    controller: _barcodeController,
                    focusNode: _focusNode,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, letterSpacing: 5),
                    decoration: InputDecoration(
                      hintText: 'انتظار قراءة الباركود...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: _isScanLoading ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()) : null,
                    ),
                    onSubmitted: _submitAttendance, // يعمل عند ضغط Enter (أو الماسح)
                  ),
                  const SizedBox(height: 20),
                  const Text('نصيحة: استخدم الموبايل كماسح لإرسال الرقم هنا.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

          // 👈 العمود الأيسر: البحث اليدوي (Fallback)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('البحث اليدوي لتسجيل الحضور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const Divider(),
                  
                  TextField(
                    controller: _searchController,
                    onChanged: _searchStudents, // 👈 يبدأ البحث أثناء الكتابة
                    decoration: InputDecoration(
                      labelText: 'ابحث بالاسم أو الباركود',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isSearchLoading ? const CircularProgressIndicator() : const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // قائمة النتائج
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final student = _searchResults[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(student['id'].toString())),
                            title: Text(student['name'] ?? 'لا يوجد اسم'),
                            subtitle: Text('الفصل: ${student['school_class']?['name'] ?? '-'} | الباركود: ${student['barcode']}'),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                // 🎯 تسجيل الحضور يدوياً باستخدام باركود الطالب
                                _submitAttendance(student['barcode']); 
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('تسجيل حضور'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_searchController.text.length >= 3 && _searchResults.isEmpty && !_isSearchLoading)
                    const Center(child: Text('لا يوجد طلاب مطابقون لمعايير البحث.')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}