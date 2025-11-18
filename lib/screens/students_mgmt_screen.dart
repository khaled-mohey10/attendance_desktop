import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart'; // يعتمد على ملف AuthService

class StudentsMgmtScreen extends StatefulWidget {
  const StudentsMgmtScreen({super.key});

  @override
  State<StudentsMgmtScreen> createState() => _StudentsMgmtScreenState();
}

class _StudentsMgmtScreenState extends State<StudentsMgmtScreen> {
  List<dynamic> _students = [];
  List<dynamic> _classes = []; // نحتاج قائمة الفصول لنموذج الإضافة/التعديل
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData(); // جلب قائمة الطلاب والفصول عند البداية
  }

  // --- 1. جلب البيانات (طلاب + فصول) ---
  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      // جلب الطلاب (GET /api/students)
      final studentsResp = await http.get(
        Uri.parse('${AuthService.baseUrl}/students'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      // جلب الفصول (GET /api/classes)
      final classesResp = await http.get(
        Uri.parse('${AuthService.baseUrl}/classes'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (studentsResp.statusCode == 200 && classesResp.statusCode == 200) {
        setState(() {
          _students = jsonDecode(studentsResp.body)['students'];
          _classes = jsonDecode(classesResp.body)['classes'];
          _isLoading = false;
        });
      } else {
        _showError("فشل تحميل البيانات");
      }
    } catch (e) {
      _showError("خطأ في الاتصال: $e");
    }
  }

  // --- 2. الإضافة والتعديل (شكل النموذج) ---
  Future<void> _saveStudent({Map<String, dynamic>? existingStudent}) async {
    final isEdit = existingStudent != null;
    
    final nameController = TextEditingController(text: isEdit ? existingStudent['name'] : '');
    final barcodeController = TextEditingController(text: isEdit ? existingStudent['barcode'] : '');
    // افتراض ID ولي الأمر (يمكن لاحقاً إضافة شاشة لإدارتهم)
    final parentIdController = TextEditingController(text: isEdit ? existingStudent['parent_id'].toString() : '2'); 
    
    // تحديد الفصل المبدئي
    int? selectedClassId = isEdit ? existingStudent['school_class_id'] : (_classes.isNotEmpty ? _classes.first['id'] : null);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل بيانات طالب' : 'إضافة طالب جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الطالب', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: 'الباركود', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              // Dropdown للفصول
              DropdownButtonFormField<int>(
                value: selectedClassId,
                decoration: const InputDecoration(labelText: 'الفصل', border: OutlineInputBorder()),
                items: _classes.map<DropdownMenuItem<int>>((c) {
                  return DropdownMenuItem(value: c['id'], child: Text(c['name']));
                }).toList(),
                onChanged: (val) => selectedClassId = val,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: parentIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID ولي الأمر (مثال: 2)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // إغلاق النافذة
              await _submitSave(
                id: isEdit ? existingStudent['id'] : null,
                name: nameController.text,
                barcode: barcodeController.text,
                classId: selectedClassId!,
                parentId: parentIdController.text,
              );
            },
            child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  // تنفيذ الحفظ (POST/PUT) في السيرفر
  Future<void> _submitSave({int? id, required String name, required String barcode, required int classId, required String parentId}) async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final isEdit = id != null;
      
      // تحديد الرابط والـ HTTP Method
      final url = Uri.parse('${AuthService.baseUrl}/students${isEdit ? '/$id' : ''}');
      final method = isEdit ? http.put : http.post; 

      final response = await method(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'barcode': barcode,
          'school_class_id': classId,
          'parent_id': int.tryParse(parentId) ?? 2, // تحويل لنوع int
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess(isEdit ? "تم التعديل بنجاح" : "تمت الإضافة بنجاح");
        _fetchInitialData(); // تحديث القائمة
      } else {
        final err = jsonDecode(response.body);
        _showError(err['message'] ?? "حدث خطأ");
      }
    } catch (e) {
      _showError("خطأ: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. حذف طالب (DELETE) ---
  Future<void> _deleteStudent(int id) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'تأكيد الحذف',
      desc: 'هل أنت متأكد من حذف هذا الطالب نهائياً؟ (سيتم حذف كل سجلات حضوره)',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        setState(() => _isLoading = true);
        try {
          final token = await AuthService.getToken();
          // استخدام الرابط الصحيح: DELETE /api/students/{id}
          final response = await http.delete(
            Uri.parse('${AuthService.baseUrl}/students/$id'),
            headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
          );

          if (response.statusCode == 200) {
            _showSuccess("تم الحذف بنجاح");
            _fetchInitialData();
          } else {
            _showError("فشل الحذف");
            setState(() => _isLoading = false);
          }
        } catch (e) {
          _showError("خطأ: $e");
        }
      },
    ).show();
  }

  // دوال مساعدة
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
        title: const Text('إدارة الطلاب'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _classes.isNotEmpty ? () => _saveStudent() : null, // لا تعمل لو لا يوجد فصول
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('الاسم')),
                    DataColumn(label: Text('الباركود')),
                    DataColumn(label: Text('الفصل')),
                    DataColumn(label: Text('تحكم')), // أزرار التعديل والحذف
                  ],
                  rows: _students.map((student) {
                    return DataRow(cells: [
                      DataCell(Text(student['id'].toString())),
                      DataCell(Text(student['name'])),
                      DataCell(Text(student['barcode'])),
                      DataCell(Text(student['school_class'] != null ? student['school_class']['name'] : '-')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _saveStudent(existingStudent: student),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteStudent(student['id']),
                            tooltip: 'حذف',
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
    );
  }
}