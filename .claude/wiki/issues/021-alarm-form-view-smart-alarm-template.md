---
status: done
---

## Parent PRD

`.claude/wiki/prd/focusplan-swift-mascot-mcp-web.md`

## What to build

Màn SwiftUI MỚI `AlarmFormView` theo template "Smart Alarm" (ảnh tham khảo user cung cấp): header giờ lớn, mục Repeat 7 nút ngày (T2–CN), 4 toggle cài đặt (Loop alarm audio / Vibrate / System volume max / Show notification — on màu tím), CTA lớn "Create Alarm", hint text trang trí. "Create Alarm" có tác dụng THẬT — nối vào hạ tầng alarm issue 005 (AlarmPlanner/AlarmScheduler/TodayScheduleService); cấu hình persist giữa các phiên. Toggle nào iOS không có public API (vd System volume max) → chốt ở plan: ghi rõ giới hạn hoặc lược bỏ, không hứa quá khả năng OS. Phủ `accessibilityIdentifier` theo chuẩn issue 019 ngay từ đầu.

## Acceptance criteria

- [x] AlarmFormView hiển thị đúng cấu trúc template: giờ lớn, Repeat 7 ngày toggle được, 4 toggle cài đặt, CTA "Create Alarm".
- [x] Bấm "Create Alarm" → cấu hình được lưu (persist qua relaunch) và ảnh hưởng thật tới hành vi chuỗi alarm (mức map cụ thể chốt ở plan).
- [x] Mọi control có `accessibilityIdentifier` theo naming convention issue 019 (MCP điều khiển được màn này).
- [x] Toàn bộ test suite xanh; có test cho logic map cấu hình → hành vi alarm (tách thuần) + XCUITest flow tạo alarm qua UI.

## Blocked by

- Blocked by `.claude/wiki/issues/020-mcp-control-server-xcuitest-bridge.md`

## User stories addressed

- User story 6 (giờ to rõ)
- User story 7 (repeat 7 ngày)
- User story 8 (4 toggle)
- User story 9 (Create Alarm có tác dụng thật)
- User story 19 (persist)
