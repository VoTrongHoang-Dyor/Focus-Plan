# Thiết kế: Flutter App Shell + Auth Demo (UI-only prototype)

## Bối cảnh

PRD `claude/wiki/prd/focus-scheduler.md` (status: Active) và issue `claude/wiki/issues/001-ios-app-shell-supabase-auth.md` đã chốt stack mobile thật là **Native iOS (Swift) + Supabase Auth**. Yêu cầu build bằng Flutter chạy trên phone ảo đi ngược quyết định đó.

Đã hỏi và chốt với user:

- Flutter chỉ dùng để dựng **UI demo/prototype** (click-through), không phải bản build thật. Kế hoạch Swift native trong PRD giữ nguyên, không supersede.
- Slice đầu tiên bám theo đúng thứ tự Kanban đã có: **App Shell + Auth** (issue 001), dựng lại bằng UI Flutter thay vì Swift.
- Giao diện tham khảo bộ ảnh MyPlan tại `assets/1.jpg`–`5.jpg`, cụ thể là ảnh `1.jpg` (Today screen) cho layout Home.
- Vì không có backend thật, "session persist" (một acceptance criteria của issue 001) được mô phỏng bằng lưu cục bộ (`shared_preferences`) — không phải qua Supabase/network.

Vì đây là bản demo UI, **không cần bất kỳ API key nào** ở slice này (Supabase/Gemini/Stripe chỉ cần khi làm bản Swift thật sau này).

## Mục tiêu

Dựng một Flutter app chạy được trên iOS Simulator, tái hiện đúng 4 acceptance criteria của issue 001 bằng mock auth cục bộ, với phong cách hình ảnh lấy cảm hứng từ ảnh Today-screen MyPlan (`assets/1.jpg`), nhưng dùng một bảng màu/identity nhất quán cho toàn app (không đổi theme theo từng màn hình như ảnh gốc).

## Ngoài phạm vi

- Không có Supabase/backend thật — mọi thao tác đăng nhập/đăng ký là mock cục bộ, chấp nhận mọi email/password hợp lệ về mặt hình thức.
- Không có task list thật, không có bottom nav tabs khác (Stats/Alarm/Discover) — Home chỉ là empty state.
- Không validate email/password nghiêm ngặt (chỉ kiểm tra field không rỗng + format email cơ bản).
- Không có Android — chỉ chạy iOS Simulator (đã xác nhận máy có sẵn Xcode Simulator, không có Android SDK).
- Không đổi bất kỳ trạng thái `status` nào trong PRD/decision log/issue 001 — track Swift native vẫn là kế hoạch build thật duy nhất.

## Màn hình & luồng điều hướng

```
App launch
    │
    ▼
Splash (đọc shared_preferences: isLoggedIn?)
    │                              │
    │ false                        │ true
    ▼                              ▼
Sign In ──(link)──> Sign Up      Home (Today, empty state)
    │                              │
    │ (submit hợp lệ)              │ (tap Sign Out icon)
    └──────────────────────────────┘
              (quay lại Sign In, xoá session cục bộ)
```

1. **Splash** — không có UI phức tạp, chỉ đọc flag lúc khởi động rồi điều hướng ngay (không cần animation).
2. **Sign In** — field email, field password, nút "Đăng nhập", text link "Chưa có tài khoản? Tạo tài khoản" điều hướng sang Sign Up. Submit hợp lệ → lưu `isLoggedIn=true` + email vào `shared_preferences` → sang Home.
3. **Sign Up** — field email, password, xác nhận password, nút "Tạo tài khoản", link quay lại Sign In. Submit hợp lệ → lưu session tương tự Sign In → sang Home thẳng (không bắt đăng nhập lại).
4. **Home (Today, empty state)** — layout tham chiếu `assets/1.jpg`: thanh ngày trong tuần ở trên, dòng chào (hiển thị email vừa đăng nhập), khu vực danh sách rỗng với placeholder text ("Chưa có task nào — sẽ thêm ở slice sau"), icon đăng xuất ở góc trên phải. Tap icon này → xoá `shared_preferences` → về Sign In.

## Phong cách hình ảnh

- Nguồn tham chiếu: `assets/1.jpg` (Today screen) cho layout Home — thanh ngày dạng dải ngang, card bo góc lớn, danh sách dạng dòng có icon bên trái.
- Khác với bộ ảnh MyPlan gốc (đổi theme màu mint/hồng/tím/xanh/cam theo từng slide giới thiệu tính năng), app này dùng **một bảng màu cố định** xuyên suốt mọi màn hình: nền trắng/xám nhạt, accent tím-chàm (gần tông ảnh `3.jpg` – Stats), card bo góc lớn, typography đậm cho tiêu đề/nhạt cho phụ đề — nhất quán vì đây là một app, không phải slide quảng cáo nhiều tính năng.
- Material 3 làm nền tảng component (`TextField`, `FilledButton`, `Card`), tuỳ biến `ColorScheme` theo accent tím-chàm nói trên.

## Kiến trúc kỹ thuật

- **State management**: `setState` cục bộ trong từng screen, không thêm Provider/Riverpod/Bloc — scope chỉ 4 màn hình, thêm state management framework là over-engineering.
- **Persistence**: package `shared_preferences`, lưu 2 key: `isLoggedIn` (bool), `userEmail` (string). Không mã hoá, không cần vì đây là mock demo cục bộ.
- **Cấu trúc thư mục**:
  ```
  lib/
    main.dart          # MaterialApp, route tới Splash
    theme.dart          # ColorScheme, TextTheme dùng chung
    screens/
      splash_screen.dart
      sign_in_screen.dart
      sign_up_screen.dart
      home_screen.dart
  ```
- **Validate form**: dùng `Form` + `TextFormField` validator có sẵn của Flutter, không viết logic validate email phức tạp (regex cơ bản đủ dùng).
- **Chạy demo**: `flutter run -d "iPhone 17 Pro"` (Simulator đã cài sẵn qua Xcode, không cần setup thêm; nếu Simulator chưa boot, `flutter run` tự boot).

## Kiểm thử / xác nhận

Đây là UI prototype, không phải deep module logic (khác với Scheduling Engine/Gamification core mà PRD yêu cầu test tự động) — xác nhận bằng chạy thủ công trên Simulator theo đúng 4 acceptance criteria của issue 001:

- [ ] Tạo tài khoản mới ở Sign Up → vào thẳng Home.
- [ ] Thoát app (hoặc hot-restart), mở lại → vẫn ở Home (session persist qua `shared_preferences`).
- [ ] Tap Sign Out ở Home → quay lại Sign In, session cục bộ bị xoá.
- [ ] Từ Sign In, đăng nhập lại bằng email/password bất kỳ hợp lệ → vào Home, thấy empty state.

Không viết automated test cho slice này (UI prototype thuần, theo đúng phạm vi "ngoài test tự động" mà PRD đã ghi cho UI/luồng không phải deep module).
