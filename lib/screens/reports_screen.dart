import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // --- ⚠️ إعدادات الاتصال ⚠️ ---
  final String _apiToken = "1|hSaGURid6SEDSgRldg29cskExu5ZXyj9uTcW1xuc1418b5b3"; // ضع التوكن هنا
  final String _baseUrl = "http://127.0.0.1:8000/api";

  List<dynamic> _reportData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDailyReport(); // جلب البيانات بمجرد فتح الشاشة
  }

  // --- دالة جلب التقرير من السيرفر ---
  Future<void> _fetchDailyReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reports/daily'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reportData = data['report']; // نأخذ القائمة الموجودة داخل 'report'
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل البيانات: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في الاتصال: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الحضور اليومي'),
        backgroundColor: Colors.indigo, // لون مختلف لتمييز الشاشة
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDailyReport, // زر تحديث البيانات
            tooltip: 'تحديث القائمة',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                    ElevatedButton(onPressed: _fetchDailyReport, child: const Text('حاول مجدداً'))
                  ],
                ))
              : _buildReportTable(),
    );
  }

  // --- بناء الجدول ---
  Widget _buildReportTable() {
    if (_reportData.isEmpty) {
      return const Center(child: Text('لا توجد بيانات لليوم'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الفصل', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('وقت الحضور', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _reportData.map((record) {
            // تحديد لون الحالة
            final isPresent = record['status'] == 'present';
            final statusColor = isPresent ? Colors.green : Colors.red;
            final statusText = isPresent ? 'حاضر' : 'غائب';

            return DataRow(cells: [
              DataCell(Text(record['student_id'].toString())),
              DataCell(Text(record['student_name'] ?? '-')),
              DataCell(Text(record['class_name'] ?? '-')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              DataCell(Text(record['scan_time'] ?? '--:--')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}