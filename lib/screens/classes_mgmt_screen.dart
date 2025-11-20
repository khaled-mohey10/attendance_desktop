import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';

class ClassesMgmtScreen extends StatefulWidget {
  const ClassesMgmtScreen({super.key});

  @override
  State<ClassesMgmtScreen> createState() => _ClassesMgmtScreenState();
}

class _ClassesMgmtScreenState extends State<ClassesMgmtScreen> {
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses(); // جلب قائمة الفصول عند البداية
  }

  // --- 1. جلب الفصول (GET /api/classes) ---
  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/classes'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _classes = jsonDecode(response.body)['classes'];
          _isLoading = false;
        });
      } else {
        _showError("فشل تحميل البيانات");
      }
    } catch (e) {
      _showError("خطأ في الاتصال");
    }
  }

  // --- 2. الإضافة والتعديل (شكل النموذج) ---
  Future<void> _saveClass({Map<String, dynamic>? existingClass}) async {
    final isEdit = existingClass != null;
    final nameController = TextEditingController(text: isEdit ? existingClass['name'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل اسم الفصل' : 'إضافة فصل جديد'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'اسم الفصل', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); 
              await _submitSave(
                id: isEdit ? existingClass['id'] : null,
                name: nameController.text,
              );
            },
            child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  // تنفيذ الحفظ (POST/PUT) في السيرفر
  Future<void> _submitSave({int? id, required String name}) async {
    if (name.isEmpty) {
        _showError("اسم الفصل لا يمكن أن يكون فارغاً");
        return;
    }
    
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final isEdit = id != null;
      
      final url = Uri.parse('${AuthService.baseUrl}/classes${isEdit ? '/$id' : ''}');
      final method = isEdit ? http.put : http.post; 

      final response = await method(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess(isEdit ? "تم التعديل بنجاح" : "تمت الإضافة بنجاح");
        _fetchClasses(); 
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

  // --- 3. حذف فصل (DELETE) ---
  Future<void> _deleteClass(int id) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'تأكيد الحذف',
      desc: 'هل أنت متأكد من حذف هذا الفصل؟ (سيؤثر على الطلاب المرتبطين به)',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        setState(() => _isLoading = true);
        try {
          final token = await AuthService.getToken();
          // ملاحظة: بما أن الباك اند (Laravel) يستخدم onDelete('cascade')، فسيتم حذف الطلاب أيضاً، لذا كن حذراً!
          final response = await http.delete(
            Uri.parse('${AuthService.baseUrl}/classes/$id'),
            headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
          );

          if (response.statusCode == 200) {
            _showSuccess("تم الحذف بنجاح");
            _fetchClasses();
          } else {
            _showError("فشل الحذف");
          }
        } catch (e) {
          _showError("خطأ: $e");
        } finally {
          setState(() => _isLoading = false);
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
        title: const Text('إدارة الفصول'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _saveClass(), // فتح نافذة الإضافة
        backgroundColor: Colors.purple,
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
                    DataColumn(label: Text('اسم الفصل')),
                    DataColumn(label: Text('تاريخ الإضافة')),
                    DataColumn(label: Text('تحكم')), // أزرار التعديل والحذف
                  ],
                  rows: _classes.map((c) {
                    return DataRow(cells: [
                      DataCell(Text(c['id'].toString())),
                      DataCell(Text(c['name'])),
                      DataCell(Text(c['created_at'].toString().split('T').first)), // عرض التاريخ فقط
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _saveClass(existingClass: c),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteClass(c['id']),
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