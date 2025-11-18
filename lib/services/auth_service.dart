import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // تأكد أن هذا الرابط صحيح ويعمل
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // حفظ التوكن
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // استرجاع التوكن
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // تسجيل الخروج (حذف التوكن)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}