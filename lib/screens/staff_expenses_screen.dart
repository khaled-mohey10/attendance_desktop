import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';

class StaffExpensesScreen extends StatefulWidget {
  const StaffExpensesScreen({super.key});

  @override
  State<StaffExpensesScreen> createState() => _StaffExpensesScreenState();
}

class _StaffExpensesScreenState extends State<StaffExpensesScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isPosting = false;
  
  final List<String> _categories = ['تصوير', 'أدوات مكتبية', 'صيانة', 'مشتريات عامة'];

  // --- دالة تسجيل المصروف التشغيلي ---
  Future<void> _submitExpense() async {
    if (_amountController.text.isEmpty || _selectedCategory == null || _descriptionController.text.isEmpty) {
      _showError("يرجى ملء كل الحقول.");
      return;
    }

    setState(() => _isPosting = true);
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      // POST /api/expenses
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/expenses'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': double.tryParse(_amountController.text),
          'description': _descriptionController.text,
          'category': _selectedCategory,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('تم تسجيل المصروف بنجاح.');
        _amountController.clear();
        _descriptionController.clear();
        setState(() => _selectedCategory = null);
      } else {
        final err = jsonDecode(response.body);
        _showError(err['message'] ?? "فشل تسجيل المصروف.");
      }
    } catch (e) {
      _showError("خطأ في الاتصال: $e");
    } finally {
      setState(() => _isPosting = false);
    }
  }
  
  void _showError(String msg) {
    AwesomeDialog(context: context, dialogType: DialogType.error, title: 'خطأ', desc: msg).show();
  }
  void _showSuccess(String msg) {
    AwesomeDialog(context: context, dialogType: DialogType.success, title: 'نجاح', desc: msg, autoHide: const Duration(seconds: 2)).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل المصروفات التشغيلية'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_money, size: 80, color: Colors.orange),
              const SizedBox(height: 20),

              // حقل المبلغ
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ المدفوع', border: OutlineInputBorder(), prefixIcon: Icon(Icons.money)),
              ),
              const SizedBox(height: 20),

              // اختيار التصنيف
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'تصنيف المصروف', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedCategory = newValue);
                },
              ),
              const SizedBox(height: 20),

              // الوصف
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'وصف مفصل (لماذا تم دفع المبلغ؟)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),

              // زر التسجيل
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isPosting ? null : _submitExpense,
                  icon: _isPosting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save, color: Colors.white),
                  label: const Text('تسجيل المصروف', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}