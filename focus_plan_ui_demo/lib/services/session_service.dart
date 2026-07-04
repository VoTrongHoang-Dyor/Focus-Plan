import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyLoggedIn = 'isLoggedIn';
  static const _keyEmail = 'userEmail';
  static const _keyName = 'userName';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  /// [name] chỉ được lưu khi có giá trị (đăng nhập lại không nhập tên → giữ
  /// tên đã lưu trước đó).
  static Future<void> signIn(String email, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_keyName, name.trim());
    }
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
  }

  /// Tên hiển thị: ưu tiên [name] đã lưu, nếu rỗng thì lấy phần trước @ của email.
  static String displayName(String? name, String email) {
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }
}
