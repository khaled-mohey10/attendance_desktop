import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';

class FinanceMgmtScreen extends StatefulWidget {
  const FinanceMgmtScreen({super.key});

  @override
  State<FinanceMgmtScreen> createState() => _FinanceMgmtScreenState();
}

class _FinanceMgmtScreenState extends State<FinanceMgmtScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedStudent;

  bool _isSearchLoading = false;
  bool _isBalanceLoading = false;
  Map<String, dynamic>? _balanceData;

  // للمدفوعات
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // دوال الاتصال بالباك اند (تستخدم الروابط المالية الجديدة)

  Future<void> _searchStudents(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isSearchLoading = true);
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/students?search=$query'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = jsonDecode(response.body)['students'];
        });
      }
    } catch (e) {
      // تجاهل
    } finally {
      setState(() => _isSearchLoading = false);
    }
  }
  
  // جلب الرصيد وحالة الدفع للطالب المختار
  Future<void> _fetchBalance() async {
    if (_selectedStudent == null) return;
    
    setState(() => _isBalanceLoading = true);
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      // GET /api/finance/balance/{studentId}
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/finance/balance/${_selectedStudent!['id']}'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _balanceData = data;
        });
      } else {
        _showError("فشل جلب الرصيد.");
      }
    } catch (e) {
      _showError("خطأ في الاتصال: $e");
    } finally {
      setState(() => _isBalanceLoading = false);
    }
  }

  // تنفيذ تسجيل دفعة (Payment)
  Future<void> _submitPayment() async {
    if (_selectedStudent == null || _amountController.text.isEmpty) {
      _showError("يجب اختيار طالب وإدخال المبلغ.");
      return;
    }

    setState(() => _isBalanceLoading = true);
    final token = await AuthService.getToken();
    if (token == null) return;

    // الحصول على الشهر الحالي (YYYY-MM)
    final currentPeriod = DateTime.now().toString().substring(0, 7); 

    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/payments'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': _selectedStudent!['id'],
          'amount': double.tryParse(_amountController.text),
          'notes': _notesController.text,
          'period_month': currentPeriod, // إرسال الشهر الحالي
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('تم تسجيل دفعة الشهر بنجاح.');
        _amountController.clear();
        _notesController.clear();
        _fetchBalance(); // تحديث الرصيد وحالة الدفع
      } else {
        final err = jsonDecode(response.body);
        _showError(err['message'] ?? "فشل تسجيل الدفعة.");
      }
    } catch (e) {
      _showError("خطأ في الاتصال: $e");
    } finally {
      setState(() => _isBalanceLoading = false);
    }
  }

  // دوال الواجهة المساعدة
  void _selectStudent(Map<String, dynamic> student) {
    setState(() {
      _selectedStudent = student;
      _searchResults = [];
      _searchController.clear();
    });
    _fetchBalance(); 
  }
  
  void _showError(String msg) {
    AwesomeDialog(context: context, dialogType: DialogType.error, title: 'خطأ', desc: msg).show();
  }
  void _showSuccess(String msg) {
    AwesomeDialog(context: context, dialogType: DialogType.success, title: 'نجاح', desc: msg, autoHide: const Duration(seconds: 2)).show();
  }
  
  // دالة بناء واجهة الرصيد
  Widget _buildBalanceWidget() {
    if (_selectedStudent == null) {
      return const Center(child: Text('اختر طالباً لعرض حالته المالية.'));
    }
    if (_isBalanceLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_balanceData == null) {
      return const Center(child: Text('فشل جلب بيانات الرصيد.'));
    }

    final isPaid = _balanceData!['monthly_fee_paid'] ?? false;
    final balanceColor = isPaid ? Colors.green : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الطالب المختار: ${_selectedStudent!['name']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Divider(),
          
          // --- عرض حالة الدفع الشهرية (الأهم) ---
          Card(
            color: balanceColor.withOpacity(0.1),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(isPaid ? Icons.check_circle : Icons.warning, size: 40, color: balanceColor),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حالة اشتراك شهر ${ _balanceData!['current_period'].toString().substring(5)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(isPaid ? '✅ تم دفع اشتراك هذا الشهر بالكامل.' : '❌ لم يتم دفع اشتراك هذا الشهر.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: balanceColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          // نموذج تسجيل الدفعات
          Text('تسجيل دفعة اشتراك جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ المدفوع', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // زر تسجيل دفعة (Payment)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitPayment,
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: const Text('تسجيل دفعة اشتراك الشهر الحالي', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ),

          const SizedBox(height: 30),
          // عرض إجمالي الدفعات التاريخية
          Text('إجمالي الدفعات السابقة: ${_balanceData!['total_payments'].toStringAsFixed(2)} جنيه', style: const TextStyle(fontSize: 16, color: Colors.grey)),

        ],
      ),
    );
  }

  // --- بناء واجهة المستخدم الرئيسية ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإدارة المالية ورصيد الطلاب'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // 👈 العمود الأيسر: البحث عن الطالب
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('البحث عن طالب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  TextField(
                    controller: _searchController,
                    onChanged: _searchStudents,
                    decoration: InputDecoration(
                      labelText: 'ابحث بالاسم أو الباركود',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isSearchLoading ? const CircularProgressIndicator() : const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // قائمة نتائج البحث
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
                            subtitle: Text('الفصل: ${student['school_class']?['name'] ?? '-'}'),
                            onTap: () => _selectStudent(student), 
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_searchController.text.length >= 2 && _searchResults.isEmpty && !_isSearchLoading)
                    const Center(child: Text('لا يوجد طلاب مطابقون.')),
                ],
              ),
            ),
          ),
          
          // 👈 العمود الأيمن: عرض الرصيد ونماذج العمليات
          Expanded(
            flex: 2,
            child: _buildBalanceWidget(),
          ),
        ],
      ),
    );
  }
}