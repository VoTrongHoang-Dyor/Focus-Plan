---
status: Active
date: 2026-07-05
---

# FocusPlan Swift App — UI/Engineering Decision Log (Mascot + MCP + Web)

## Phạm vi

**`FocusPlan/` (Swift app thật)** — KHÔNG phải `focus_plan_ui_demo/` (Flutter prototype).

*Lịch sử chốt phạm vi: grill ban đầu (Round 1-2) soạn trên ngữ cảnh Flutter demo → nhận ra hiểu nhầm → chỉnh lại phạm vi Swift app thật (Round 3). Quyết định này chốt sau khi xác nhận rõ phạm vi.*

## Linh vật (Mascot) — kích thước động theo màn

**Quyết định:**
- Kích thước **cố định theo từng màn**: HomeView nhỏ (48px?), AlarmFormView/Onboarding to (120px?). Phong cách tham khảo Duolingo (linh vật lớn, biểu cảm, nổi bật ở màn khuyến khích).
- **Asset:** tái dùng PNG từ Flutter demo (`focus_plan_ui_demo/assets/images/mascot_body.png` + `mascot_arm.png` — đã tách layer + animation ngó nghiêng/nhún/vẫy 1700ms). **Không tạo asset mới.**
- **Triển khai:** SwiftUI component `Mascot(size:)` — tương tự cấu trúc Flutter, tuân theo API hiện có.

## Template Smart Alarm — AlarmFormView mới

**Quyết định:**
- **Tạo UI mới `AlarmFormView`** — chưa tồn tại bên Swift (issue 005 chỉ có logic `AlarmPlanner`/`AlarmScheduler`/`TodayScheduleService`; không có UI form riêng).
- Thiết kế dựa ảnh tham khảo "Smart Alarm" user cung cấp:
  - Header: "Today" (hoặc tên task cụ thể), giờ lớn (HH:mm format).
  - Mục "Repeat": 7 nút ngày (T2–CN), toggle on/off.
  - Mục "Settings": 4 toggle switch (Loop alarm audio / Vibrate / System volume max / Show notification) — on màu tím.
  - CTA: nút lớn tím "Create Alarm", dưới có hint text trang trí (vd "You can do it").
  - **Mascot to** ở header/background — không làm onboarding riêng.
- **Không thay** AlarmSettingsScreen (vì chưa tồn tại) — chỉ tạo mới theo thiết kế.

## MCP Control — Custom Server (Trước UI)

**Quyết định:**
- **Custom MCP server (stdio)** bridge qua XCUITest/accessibilityIdentifier — điều khiển app như automation tester.
- **Thứ tự:** MCP server **làm TRƯỚC `AlarmFormView`** (Round 1 chốt "làm trước UI") → AlarmFormView xây dựng với chuẩn `accessibilityIdentifier` đầy đủ từ đầu.
- **Scope accessibility production:** core flows (Auth, Task creation, Alarm creation) trước — đầy đủ `accessibilityIdentifier` cho những flow AI cần điều khiển.
- **Kiến trúc cụ thể** (mô phỏng, chờ chi tiết hơn ở PRD):
  - MCP server: Dart CLI (hoặc node) chạy stdio.
  - Bridge: giao thức gọi XCUITest harness (hoặc native XCTest driver) từ MCP → tap/input/read UI qua accessibility tree.
  - Không expose deep link / HTTP-WebSocket trong app (tránh rủi ro bảo mật).

## CI/CD + Deployment

**Quyết định:**
- **GitHub Actions** chạy `xcodebuild test` (unit + UITest) + build IPA.
- Deploy: **TestFlight** (beta testing) trước, App Store khi ready.
- **Accessibility** production scope: core flows (auth, task, alarm) — phủ `accessibilityIdentifier` đầy đủ, pass WCAG 2.1 AA baseline.

## Web — Conditional Roadmap

**Quyết định:**
- Trigger: **$100/tháng MRR** (recurring) từ app.
- Ghi thành **conditional roadmap** — không làm ngay. Khi app đạt mốc $100/tháng, team quyết định tiếp tục web hay prioritize iOS deeper.

## Quy trình phát triển

1. **MCP server** (Round 3-4): Thiết kế giao thức + implement stdio bridge; phủ XCUITest harness.
2. **AlarmFormView** (kế tiếp): xây dựng theo thiết kế Smart Alarm + chuẩn MCP identifier.
3. **Mascot component**: import asset từ Flutter demo + wrapping SwiftUI.
4. **Integration**: TodayScheduleService arm alarm → AlarmFormView tạo alarm → UI display lịch "Today" (issue nào phụ trách sẽ xác định sau).

## Still Open

- **Chi tiết MCP server API**: bộ lệnh nào expose (tap, input, read, wait, screenshot)? Timeout? Error handling?
- **XCUITest driver khởi động**: từ dev/CI, MCP server gọi vào như thế nào? stdio pipe, network socket?
- **Tiêu chí "AI điều khiển không cần đọc doc"**: cần phải đạt chuẩn gì? (vd accessibility label tự giải thích, phát hiện control type tự động).
- **Phần nối dây TodayScheduleService ↔ AlarmFormView**: khi user tạo alarm → UI hiển thị trong lịch hôm nay; sau này issue nào đảm nhận.
- **Onboarding/philosophy layer**: ghi vào đó không? (ảnh mascot to, "Set Customize Conquer" tagline, hint text). Tạm hoãn — chốt nếu onboarding là separate issue.
