---
status: Active
date: 2026-07-05
---

# PRD — FocusPlan (Swift): MCP Control + Smart Alarm UI + Mascot + CI/CD + Web Roadmap

> Nguồn: Decision Log `.claude/wiki/decisions/focusplan-swift-mascot-mcp-web-decision-log.md` (Active, 2026-07-05 — chốt sau 3 round grill).
> Phạm vi: **`FocusPlan/` — app iOS Swift thật** (KHÔNG phải `focus_plan_ui_demo/` Flutter).

## Problem Statement

FocusPlan (iOS/Swift) đã có core loop chạy được (auth, tạo task bằng NLP, habit, scheduling engine, alarm logic) nhưng:

1. **AI agent không điều khiển được app.** Người dùng (developer/owner) muốn AI agent qua MCP thao tác được app — kể cả khi agent chưa đọc tài liệu trước — để tự demo, tự QA, tự vận hành các flow. Hiện UI chỉ có vài `accessibilityLabel` rời rạc phục vụ XCUITest nội bộ, không có chuẩn identifier hệ thống, không có MCP server nào.
2. **Alarm có logic nhưng không có UI.** Issue 005 đã build chuỗi báo thức escalating (AlarmPlanner/AlarmScheduler/TodayScheduleService) nhưng user không có màn hình nào để xem/tùy chỉnh alarm — mọi thứ tự động ngầm. Người dùng muốn màn tạo/tùy chỉnh alarm theo template "Smart Alarm" đã chọn (ảnh tham khảo).
3. **App thiếu bản sắc thương hiệu.** Mascot Focus Plan đã có bên Flutter demo (asset tách layer + animation) nhưng app Swift thật chưa có mascot nào — thiếu yếu tố khích lệ/nhận diện kiểu Duolingo.
4. **Chưa có CI/CD.** Mọi build/test chạy tay local; muốn nâng chuẩn "sản phẩm thật" cần pipeline tự động.
5. **Định hướng web chưa được ghi nhận chính thức** — user muốn chốt điều kiện làm web để không phải tranh luận lại.

## Solution

1. **Custom MCP server (stdio)** bridge qua XCUITest/accessibilityIdentifier: agent AI kết nối MCP server → server điều khiển app trên simulator như một automation tester (tap, nhập text, đọc UI). App được phủ `accessibilityIdentifier` chuẩn hoá, tự mô tả, trên các core flow (auth, tạo task, alarm) để agent "đoán" được cách thao tác mà không cần doc. **MCP server làm TRƯỚC UI mới** — AlarmFormView khi build phải tuân chuẩn identifier ngay từ đầu.
2. **AlarmFormView mới** theo template Smart Alarm: header giờ lớn, mục Repeat 7 ngày, 4 toggle cài đặt (Loop alarm audio / Vibrate / System volume max / Show notification), CTA "Create Alarm", mascot to + tagline trang trí. Không làm onboarding riêng.
3. **Mascot component SwiftUI** `MascotView(size:)` tái dùng asset PNG tách layer từ Flutter demo (body + arm, animation ngó nghiêng/nhún/vẫy), kích thước cố định theo màn: Home nhỏ, AlarmFormView to (phong cách Duolingo).
4. **CI/CD GitHub Actions**: chạy `xcodebuild` test (unit + UITest) + build; hướng tới TestFlight khi ready.
5. **Web = conditional roadmap**: chỉ khởi động khi app đạt **$100/tháng MRR** — ghi nhận chính thức, không làm bây giờ.

## User Stories

1. As an AI agent (điều khiển qua MCP), I want một MCP server expose các lệnh thao tác app (liệt kê element, tap, nhập text, đọc trạng thái màn hình), so that tôi điều khiển được FocusPlan trên simulator mà không cần can thiệp tay.
2. As an AI agent, I want mọi control trong core flow có `accessibilityIdentifier` ổn định + tự mô tả (đoán được từ tên), so that tôi thao tác đúng ngay cả khi chưa đọc tài liệu về app.
3. As an AI agent, I want lệnh đọc UI trả về cấu trúc màn hình hiện tại (element nào, loại gì, identifier gì, giá trị gì), so that tôi biết mình đang ở đâu và có thể quyết định bước tiếp theo.
4. As a developer (owner), I want MCP server khởi động được từ máy dev bằng một lệnh đơn giản, so that tôi gắn nó vào Claude/agent khác nhanh chóng khi demo.
5. As a developer, I want bộ lệnh MCP có error message rõ ràng khi element không tồn tại/không tap được, so that agent tự sửa hướng thao tác thay vì kẹt im lặng.
6. As a user, I want một màn hình tạo báo thức (AlarmFormView) hiển thị giờ to rõ, so that tôi thấy ngay alarm sẽ reo lúc nào.
7. As a user, I want chọn lặp lại theo ngày trong tuần bằng 7 nút bật/tắt (T2–CN), so that tôi đặt alarm theo lịch tuần của mình.
8. As a user, I want 4 tùy chọn alarm dạng toggle — lặp âm thanh (Loop alarm audio), rung (Vibrate), max âm lượng hệ thống (System volume max), hiện notification (Show notification), so that tôi kiểm soát cách alarm hoạt động.
9. As a user, I want bấm nút "Create Alarm" để lưu cấu hình alarm, so that chuỗi báo thức escalating (đã có từ issue 005) chạy theo đúng tùy chọn tôi đặt.
10. As a user, I want thấy mascot Focus Plan kích thước lớn, biểu cảm, kèm tagline khích lệ trên màn tạo alarm, so that trải nghiệm có cảm giác động viên kiểu Duolingo thay vì form khô khan.
11. As a user, I want thấy mascot kích thước nhỏ trên màn Home, so that thương hiệu hiện diện nhẹ nhàng mà không chiếm chỗ nội dung chính.
12. As a user, I want mascot có animation sống động (ngó nghiêng/nhún/vẫy tay) như bên demo, so that app có sức sống chứ không phải ảnh tĩnh.
13. As a developer, I want mascot đóng gói thành một component SwiftUI duy nhất nhận tham số kích thước, so that thêm mascot vào màn mới chỉ mất một dòng code.
14. As a developer, I want mỗi lần push code GitHub Actions tự chạy toàn bộ unit test + UITest iOS, so that regression bị bắt trước khi merge thay vì phát hiện tay.
15. As a developer, I want CI build được artifact app (hướng tới TestFlight), so that beta tester nhận build mà tôi không phải build tay.
16. As a reviewer (QA), I want CI hiển thị kết quả test rõ ràng theo từng lần chạy, so that vòng lặp coder↔reviewer có bằng chứng khách quan không phụ thuộc máy cá nhân.
17. As an owner, I want điều kiện "làm web khi đạt $100/tháng MRR" được ghi chính thức trong wiki, so that team không tranh luận lại và không làm web sớm lãng phí.
18. As an AI agent, I want các flow auth (sign in/sign up/sign out) thao tác được qua identifier chuẩn, so that tôi tự chạy được kịch bản end-to-end từ đăng nhập tới tạo task/alarm.
19. As a user, I want alarm settings tôi đặt được giữ lại (persist) giữa các lần mở app, so that không phải đặt lại mỗi lần.
20. As a developer, I want chuẩn đặt `accessibilityIdentifier` được tài liệu hoá ngắn gọn (naming convention), so that mọi UI mới sau này (kể cả ngoài scope PRD này) theo cùng chuẩn.

## Implementation Decisions

- **Thứ tự thực hiện (chốt từ grill):** (1) MCP server + phủ accessibilityIdentifier core flows → (2) AlarmFormView (build theo chuẩn identifier có sẵn) → (3) Mascot component + gắn vào Home/AlarmFormView → (4) CI/CD → (5) Web chỉ ghi roadmap.
- **MCP server:**
  - Giao thức MCP chuẩn qua **stdio** (agent như Claude kết nối trực tiếp).
  - Bridge cơ chế **XCUITest/accessibility tree** — điều khiển app như automation tester trên simulator. KHÔNG nhúng command channel (deep link / HTTP / WebSocket) vào app — tránh rủi ro bảo mật, app production không đổi hành vi.
  - Bộ lệnh tối thiểu (chi tiết chốt ở bước plan): liệt kê element màn hình hiện tại, tap theo identifier, nhập text vào field theo identifier, đọc giá trị/label, chờ element xuất hiện. Screenshot là nice-to-have.
  - Ngôn ngữ/runtime của server: để coder quyết (ưu tiên đơn giản, chạy được bằng 1 lệnh trên máy dev có Xcode).
- **AccessibilityIdentifier:**
  - Phủ **core flows trước**: auth (sign in/up/out), tạo task (AddTask/TaskForm/TaskList), alarm (AlarmFormView khi có).
  - Naming convention tự mô tả, ổn định, tài liệu hoá ngắn gọn — mục tiêu "AI đoán được không cần doc".
  - Các `accessibilityLabel` tiếng Việt hiện có (phục vụ XCUITest cũ) giữ nguyên — identifier là lớp bổ sung, không phá test hiện có.
- **AlarmFormView:**
  - Màn SwiftUI MỚI (chưa tồn tại) theo template Smart Alarm: giờ lớn, Repeat 7 ngày, 4 toggle, CTA "Create Alarm", mascot to + tagline.
  - Cấu hình alarm phải nối vào hạ tầng alarm có sẵn (AlarmPlanner/AlarmScheduler/TodayScheduleService từ issue 005) — "Create Alarm" có tác dụng thật, không phải UI mock. Mức độ tùy chọn nào map vào hạ tầng hiện có (vd Show notification = bật/tắt arm chùm) chốt ở bước plan; tùy chọn chưa hỗ trợ được ở tầng OS (vd System volume max không có API public) hiển thị nhưng ghi rõ giới hạn hoặc lược bỏ — quyết ở plan, không hứa quá khả năng iOS.
  - Persist cấu hình alarm giữa các phiên (cơ chế lưu chốt ở plan — ưu tiên đơn giản).
- **Mascot:**
  - Component SwiftUI `MascotView(size:)`; asset PNG body/arm tái dùng từ Flutter demo (đã tách layer); animation ngó nghiêng/nhún/vẫy tương đương bản demo.
  - Kích thước cố định theo màn: Home nhỏ, AlarmFormView to. Không có onboarding screen mới.
- **CI/CD:**
  - GitHub Actions: workflow chạy `xcodegen generate` + `xcodebuild test` trên simulator iOS cho mỗi push/PR; build artifact hướng tới TestFlight (bước ký/upload có thể để sau khi có Apple Developer credentials trên CI).
  - Lưu ý ràng buộc: UITest hiện phụ thuộc Supabase project thật + secrets — plan phải quyết chạy phần nào trên CI (unit luôn chạy; UITest cần secrets/config riêng).
- **Web:** KHÔNG code gì. Chỉ là mục roadmap có điều kiện ($100/tháng MRR) đã ghi trong Decision Log; PRD nhắc lại để prd-to-issues không sinh issue implementation cho web.

## Testing Decisions

- Nguyên tắc: test hành vi bên ngoài, không test chi tiết cài đặt. Tiếp nối pattern có sẵn của repo: logic thuần tách khỏi OS/IO để unit test (như AlarmPlanner/SchedulingEngine); phần OS bọc protocol + fake (như NotificationScheduling/FakeCenter); flow end-to-end bằng XCUITest trên simulator + Supabase thật.
- **MCP server:** test theo hợp đồng lệnh — với app đang chạy trên simulator, mỗi lệnh (list/tap/type/read/wait) trả kết quả đúng và lỗi rõ ràng khi identifier sai. Kịch bản chứng minh "AI điều khiển được": chạy một flow thật (mở app → sign in → tạo task) hoàn toàn qua lệnh MCP.
- **AccessibilityIdentifier coverage:** assert qua chính MCP/XCUITest — các control core flow tra được theo identifier.
- **AlarmFormView:** logic map cấu hình → hành vi alarm tách thuần để unit test; flow tạo alarm qua UI thêm XCUITest (pattern TaskFlowUITests hiện có).
- **Mascot:** kiểm tra qua build + hiển thị (snapshot/manual) — không yêu cầu unit test animation.
- **CI/CD:** bằng chứng = workflow chạy xanh trên GitHub với chính test suite của repo.

## Out of Scope

- **Web app** — chỉ roadmap có điều kiện, không code, không issue implementation.
- **Onboarding screen mới** — user đã chốt không làm; mascot to chỉ nằm ở AlarmFormView.
- **Tạo asset mascot mới** (vector/Lottie) — tái dùng PNG demo.
- **Command channel trong app** (deep link/HTTP/WebSocket) — đã loại vì rủi ro bảo mật.
- **Critical Alerts entitlement / background mode** — giữ nguyên quyết định best-effort của issue 005.
- **MCP điều khiển trên device thật** — phạm vi là simulator (XCUITest từ máy dev/CI).
- **Các issue 006-018 hiện có** của focus-scheduler — không bị PRD này thay đổi nội dung; nếu trùng lặp (vd 011 Screen Time) xử lý ở prd-to-issues bằng tham chiếu, không viết lại.

## Further Notes

- Decision Log nguồn: `focusplan-swift-mascot-mcp-web-decision-log.md`. Các mục "Still Open" trong đó (bộ lệnh MCP chi tiết, cách khởi động XCUITest driver, tiêu chí đo "AI điều khiển không cần doc", nối dây UI hiển thị lịch Today) được chốt dần ở bước writing-plans cho từng issue — không block PRD.
- Ràng buộc môi trường đang treo từ trước (không thuộc PRD này nhưng ảnh hưởng QA chung): Gemini API hết quota (chờ user bật billing), issue 005 criteria 4 chờ user QA device thật.
- Thành quả này đồng thời phục vụ mục tiêu kép của dự án (case study quy trình + sản phẩm thật) — MCP control chính là điểm demo mạnh cho nhà tuyển dụng/khách hàng.
