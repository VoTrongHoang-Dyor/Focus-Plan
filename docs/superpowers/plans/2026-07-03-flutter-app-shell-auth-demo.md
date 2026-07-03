# Flutter App Shell + Auth Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng một Flutter app UI-only (mock auth cục bộ, không backend) chạy trên iOS Simulator, tái hiện 4 acceptance criteria của issue 001 (`.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`) với giao diện tham khảo `assets/1.jpg`.

**Architecture:** 4 screen (Splash, Sign In, Sign Up, Home) nối bằng `Navigator` cổ điển (`MaterialPageRoute`, không dùng router package). Một service tĩnh (`SessionService`) bọc `shared_preferences` làm nơi duy nhất đọc/ghi trạng thái đăng nhập. Không có state management package, không có network layer.

**Tech Stack:** Flutter 3.44.1 (Dart 3.12), Material 3, package `shared_preferences` (bản duy nhất được thêm ngoài Flutter SDK mặc định).

## Global Constraints

- Không gọi Supabase/Gemini/network thật ở bất kỳ đâu — mọi "đăng nhập/đăng ký" là mock cục bộ, chấp nhận input hợp lệ về mặt hình thức.
- Không thêm package quản lý state (Provider/Riverpod/Bloc) — chỉ `setState`.
- Chỉ target iOS Simulator, không tạo/động vào cấu hình Android.
- Không viết automated test cho slice này (theo quyết định trong spec) — xác minh bằng `flutter analyze` (static check) + chạy tay trên Simulator theo checklist.
- Không đổi `status` của bất kỳ file nào trong `.claude/wiki/` (PRD, decision log, issue) — bản Swift native trong PRD giữ nguyên là kế hoạch build thật.
- Không đụng vào việc đổi tên thư mục `claude/` → `.claude/` đang treo chưa commit trong repo — nằm ngoài phạm vi plan này.
- Dự án Flutter tạo mới tại thư mục gốc repo: `focus_plan_ui_demo/`.

---

## File Structure

```
focus_plan_ui_demo/                      # Flutter project root (flutter create --platforms=ios)
  pubspec.yaml                           # + shared_preferences dependency (Task 4)
  lib/
    main.dart                            # Entry point, MaterialApp, trỏ route ban đầu (đổi qua từng task)
    theme.dart                           # ThemeData dùng chung (Material 3, ColorScheme.fromSeed indigo)
    services/
      session_service.dart               # Bọc shared_preferences: isLoggedIn/getEmail/signIn/signOut (Task 4)
    screens/
      home_screen.dart                   # Today screen, empty state, nút Sign Out (Task 1, sửa lại Task 4)
      sign_in_screen.dart                # Form đăng nhập (Task 2, sửa lại Task 3 và Task 4)
      sign_up_screen.dart                # Form đăng ký (Task 3, sửa lại Task 4)
      splash_screen.dart                 # Kiểm tra session lúc khởi động (Task 4)
```

Mỗi file trong `screens/` chỉ chứa đúng 1 screen (1 trách nhiệm), `session_service.dart` là điểm truy cập `shared_preferences` duy nhất trong toàn app — không screen nào gọi trực tiếp package `shared_preferences`.

---

### Task 1: Scaffold project + theme + Home screen (empty state)

**Files:**
- Create: `focus_plan_ui_demo/` (toàn bộ qua `flutter create`)
- Create: `focus_plan_ui_demo/lib/theme.dart`
- Create: `focus_plan_ui_demo/lib/screens/home_screen.dart`
- Modify: `focus_plan_ui_demo/lib/main.dart`
- Delete: `focus_plan_ui_demo/test/widget_test.dart` (test mặc định của counter app, không còn khớp)

**Interfaces:**
- Produces: `ThemeData buildAppTheme()` trong `theme.dart` — dùng trong `main.dart` và mọi task sau.
- Produces: `class HomeScreen extends StatelessWidget` với constructor `HomeScreen({required String email})` — dùng bởi Task 2, 3, 4.

- [ ] **Step 1: Tạo project Flutter**

Chạy từ thư mục gốc repo:

```bash
flutter create --platforms=ios --project-name focus_plan_ui_demo focus_plan_ui_demo
cd focus_plan_ui_demo
rm test/widget_test.dart
```

Expected: lệnh in ra `All done!` và tạo thư mục `focus_plan_ui_demo/` với `lib/main.dart` mặc định (counter app).

- [ ] **Step 2: Viết `lib/theme.dart`**

```dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.light,
    ),
  );
}
```

- [ ] **Step 3: Viết `lib/screens/home_screen.dart`**

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  static const _labels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDays = List.generate(
      7,
      (i) => now.subtract(Duration(days: now.weekday % 7 - i)),
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xin chào, $email', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weekDays.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = weekDays[index];
                  final isToday = day.day == now.day && day.month == now.month;
                  return Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: isToday ? colorScheme.primary : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _labels[day.weekday % 7],
                          style: TextStyle(
                            color: isToday ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Chưa có task nào — sẽ thêm ở slice sau',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Lưu ý: nút Sign Out (`onPressed: () {}`) chưa làm gì ở task này — sẽ nối logic thật ở Task 4.

- [ ] **Step 4: Sửa `lib/main.dart`**

```dart
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const FocusPlanDemoApp());
}

class FocusPlanDemoApp extends StatelessWidget {
  const FocusPlanDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Plan Demo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(email: 'demo@example.com'),
    );
  }
}
```

- [ ] **Step 5: Kiểm tra static analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Chạy trên Simulator, xác nhận layout**

```bash
flutter run -d "iPhone 17 Pro"
```

Expected: app mở màn "Today" — thanh 7 ngày (CN→T7) với ngày hôm nay tô màu tím-chàm, dòng chào "Xin chào, demo@example.com", card giữa màn hình ghi "Chưa có task nào — sẽ thêm ở slice sau", icon logout ở góc phải AppBar (chưa cần hoạt động). Nhấn `q` trong terminal để thoát sau khi xác nhận xong.

- [ ] **Step 7: Commit**

```bash
git add focus_plan_ui_demo/
git commit -m "Scaffold Flutter UI demo with themed Home empty-state screen"
```

---

### Task 2: Sign In screen

**Files:**
- Create: `focus_plan_ui_demo/lib/screens/sign_in_screen.dart`
- Modify: `focus_plan_ui_demo/lib/main.dart`

**Interfaces:**
- Consumes: `HomeScreen({required String email})` từ Task 1.
- Produces: `class SignInScreen extends StatefulWidget` (không tham số) — dùng bởi Task 3 (link quay lại) và Task 4 (Splash điều hướng tới).

- [ ] **Step 1: Viết `lib/screens/sign_in_screen.dart`**

```dart
import 'package:flutter/material.dart';

import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nhập email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Đăng nhập', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
                  child: const Text('Chưa có tài khoản? Tạo tài khoản'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

Lưu ý: link "Tạo tài khoản" (`onPressed: () {}`) chưa điều hướng — Task 3 sẽ nối sang `SignUpScreen`.

- [ ] **Step 2: Sửa `lib/main.dart`** — đổi màn khởi động sang Sign In

```dart
import 'package:flutter/material.dart';

import 'screens/sign_in_screen.dart';
import 'theme.dart';

void main() {
  runApp(const FocusPlanDemoApp());
}

class FocusPlanDemoApp extends StatelessWidget {
  const FocusPlanDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Plan Demo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SignInScreen(),
    );
  }
}
```

- [ ] **Step 3: Kiểm tra static analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Chạy trên Simulator, xác nhận luồng**

```bash
flutter run -d "iPhone 17 Pro"
```

Expected: app mở màn "Đăng nhập". Bỏ trống form rồi bấm "Đăng nhập" → hiện lỗi validate dưới mỗi field. Nhập email hợp lệ (vd `a@b.com`) + mật khẩu ≥6 ký tự → bấm "Đăng nhập" → chuyển sang màn Home, dòng chào hiển thị đúng email vừa nhập.

- [ ] **Step 5: Commit**

```bash
git add focus_plan_ui_demo/
git commit -m "Add Sign In screen with local form validation"
```

---

### Task 3: Sign Up screen

**Files:**
- Create: `focus_plan_ui_demo/lib/screens/sign_up_screen.dart`
- Modify: `focus_plan_ui_demo/lib/screens/sign_in_screen.dart` (nối link "Tạo tài khoản")

**Interfaces:**
- Consumes: `HomeScreen({required String email})` từ Task 1.
- Produces: `class SignUpScreen extends StatefulWidget` (không tham số) — dùng bởi `sign_in_screen.dart` (task này) và Task 4 (không thay đổi thêm).

- [ ] **Step 1: Viết `lib/screens/sign_up_screen.dart`**

```dart
import 'package:flutter/material.dart';

import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nhập email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Tạo tài khoản'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Sửa `lib/screens/sign_in_screen.dart`** — nối link sang Sign Up

Thêm import ở đầu file:

```dart
import 'sign_up_screen.dart';
```

Đổi `onPressed` của `TextButton` "Chưa có tài khoản? Tạo tài khoản" từ `() {}` thành:

```dart
onPressed: () {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SignUpScreen()),
  );
},
```

- [ ] **Step 3: Kiểm tra static analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Chạy trên Simulator, xác nhận luồng 2 chiều**

```bash
flutter run -d "iPhone 17 Pro"
```

Expected: từ Sign In, bấm "Chưa có tài khoản? Tạo tài khoản" → sang màn "Tạo tài khoản" (có nút back tự động của AppBar). Bấm "Đã có tài khoản? Đăng nhập" → quay lại Sign In. Điền đủ 3 field hợp lệ (mật khẩu và xác nhận khớp) + bấm "Tạo tài khoản" → sang Home với đúng email vừa nhập. Thử để mật khẩu xác nhận sai → thấy lỗi "Mật khẩu xác nhận không khớp".

- [ ] **Step 5: Commit**

```bash
git add focus_plan_ui_demo/
git commit -m "Add Sign Up screen, wire navigation with Sign In"
```

---

### Task 4: Session persistence (SessionService + Splash + wiring Sign Out)

**Files:**
- Modify: `focus_plan_ui_demo/pubspec.yaml` (thêm dependency)
- Create: `focus_plan_ui_demo/lib/services/session_service.dart`
- Create: `focus_plan_ui_demo/lib/screens/splash_screen.dart`
- Modify: `focus_plan_ui_demo/lib/screens/home_screen.dart` (nối Sign Out thật)
- Modify: `focus_plan_ui_demo/lib/screens/sign_in_screen.dart` (gọi `SessionService.signIn`)
- Modify: `focus_plan_ui_demo/lib/screens/sign_up_screen.dart` (gọi `SessionService.signIn`)
- Modify: `focus_plan_ui_demo/lib/main.dart` (route ban đầu → Splash)

**Interfaces:**
- Consumes: `HomeScreen`, `SignInScreen`, `SignUpScreen` từ Task 1–3 (không đổi signature của các class này).
- Produces: `class SessionService` với 4 static method: `Future<bool> isLoggedIn()`, `Future<String?> getEmail()`, `Future<void> signIn(String email)`, `Future<void> signOut()`.

- [ ] **Step 1: Thêm dependency vào `pubspec.yaml`**

Trong khối `dependencies:` (ngay dưới dòng `dependencies:`, trước `flutter:`), thêm:

```yaml
  shared_preferences: ^2.3.0
```

Chạy:

```bash
flutter pub get
```

Expected: log kết thúc bằng `Got dependencies!` (không có lỗi resolve).

- [ ] **Step 2: Viết `lib/services/session_service.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyLoggedIn = 'isLoggedIn';
  static const _keyEmail = 'userEmail';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<void> signIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyEmail, email);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyEmail);
  }
}
```

- [ ] **Step 3: Viết `lib/screens/splash_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await SessionService.isLoggedIn();
    if (!mounted) return;
    if (loggedIn) {
      final email = await SessionService.getEmail();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(email: email ?? '')),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

- [ ] **Step 4: Sửa `lib/screens/home_screen.dart`** — nối Sign Out thật

Thêm import ở đầu file:

```dart
import '../services/session_service.dart';
import 'sign_in_screen.dart';
```

Thêm method vào class `HomeScreen` (trước `build`):

```dart
  Future<void> _handleSignOut(BuildContext context) async {
    await SessionService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }
```

Đổi `onPressed: () {}` của `IconButton` logout thành:

```dart
onPressed: () => _handleSignOut(context),
```

- [ ] **Step 5: Sửa `lib/screens/sign_in_screen.dart`** — lưu session khi đăng nhập

Thêm import:

```dart
import '../services/session_service.dart';
```

Đổi method `_submit` từ `void _submit()` thành:

```dart
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    await SessionService.signIn(email);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
      (route) => false,
    );
  }
```

- [ ] **Step 6: Sửa `lib/screens/sign_up_screen.dart`** — lưu session khi đăng ký

Thêm import:

```dart
import '../services/session_service.dart';
```

Đổi method `_submit` từ `void _submit()` thành:

```dart
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    await SessionService.signIn(email);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
      (route) => false,
    );
  }
```

- [ ] **Step 7: Sửa `lib/main.dart`** — route ban đầu qua Splash

```dart
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(const FocusPlanDemoApp());
}

class FocusPlanDemoApp extends StatelessWidget {
  const FocusPlanDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Plan Demo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
```

- [ ] **Step 8: Kiểm tra static analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 9: Chạy trên Simulator, xác nhận đủ 4 acceptance criteria của issue 001**

```bash
flutter run -d "iPhone 17 Pro"
```

Expected, theo đúng thứ tự:

1. Lần đầu mở app → Splash (spinner) → tự chuyển sang Sign In (chưa có session).
2. Đăng ký tài khoản mới ở Sign Up (email + mật khẩu hợp lệ, khớp confirm) → vào thẳng Home, thấy "Xin chào, <email>".
3. Trong terminal đang chạy `flutter run`, nhấn `R` (hot restart) để mô phỏng mở lại app → Splash → tự vào thẳng Home (không quay lại Sign In) — xác nhận session persist qua `shared_preferences`.
4. Bấm icon Sign Out ở Home → quay lại Sign In, session bị xoá.
5. Đăng nhập lại ở Sign In bằng email/mật khẩu hợp lệ bất kỳ → vào Home, thấy empty state đúng như Task 1.

- [ ] **Step 10: Commit**

```bash
git add focus_plan_ui_demo/
git commit -m "Add local session persistence via shared_preferences, wire Splash and Sign Out"
```

---

## Self-Review Notes

- **Spec coverage:** 4 màn hình (Splash/Sign In/Sign Up/Home) khớp đúng 4 acceptance criteria issue 001; visual style tham chiếu `assets/1.jpg` cho Home (Task 1); persistence cục bộ qua `shared_preferences` (Task 4) đúng quyết định đã chốt trong spec; không backend/network ở bất kỳ task nào.
- **Đã verify thực tế:** toàn bộ code trong 4 task đã được dựng và chạy thử trong scratchpad trước khi viết plan này — `flutter analyze` sạch (0 issue), app build và chạy thành công trên iPhone 17 Pro Simulator, màn Sign In render đúng như thiết kế (màu tím-chàm, tiếng Việt có dấu hiển thị đúng).
- **Type consistency:** `HomeScreen(email: String)` dùng nhất quán ở Task 1, 2, 3, 4. `SessionService` 4 method static dùng nhất quán ở Task 4 (không đổi tên giữa các chỗ gọi).
