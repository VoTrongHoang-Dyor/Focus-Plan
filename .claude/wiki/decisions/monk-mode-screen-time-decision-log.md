---
status: Active
date: 2026-07-06
---

# Decision Log: Monk Mode × Screen Time (refine issue 011)

## Bối cảnh

User hỏi về "Screen Time như iOS" — liệu có làm được trong app, có vi phạm không, tích hợp vào Monk Mode thế nào. Phát hiện xung đột: issue 011 hiện tại cấm dùng Screen Time entitlement cho MVP, nhưng user muốn có khả năng này.

## Quyết định chốt (3 round grill)

### 1. Kiến trúc 2 pha (supersede một phần criterion issue 011)

**Pha 1 (MVP, ship App Store)**
- KHÔNG dùng Screen Time API / Family Controls
- NỘI Apple form xin entitlement `com.apple.developer.family-controls` (distribution) **song song** — action item của user, độc lập với pha 1 implementation
- Thay vào đó: **Focus lock in-app** — khóa UI FocusPlan vào màn focus session, nhắc user bật Focus Mode / Do Not Disturb của hệ điều hành (tận dụng tín hiệu DND đang thiết kế cho Level 3 badge, issue 017)

**Pha 2 (khi Apple duyệt entitlement)**
- Chặn app thật bằng `FamilyControls` + `ManagedSettings` shield (`.individual`)
- Cho user chọn app cần chặn qua `FamilyActivityPicker` trong app
- Implementation tách riêng, timeline phụ thuộc Apple duyệt form (vài ngày–vài tuần)

### 2. Distribution: App Store công khai

Giữ nguyên quyết định PRD focus-scheduler — không thay đổi.

### 3. Tính năng BỎ hoàn toàn

**(a) Dashboard usage kiểu iOS Settings**
- Bỏ: theo dõi tổng screen time cho app khác
- Lý do: phức tạp, phụ thuộc entitlement, ngoài phạm vi Monk Mode

**(b) Deep-link sang mục Screen Time hệ thống**
- Bỏ: `App-prefs:SETTINGS_SCREEN_TIME_PARENT` hoặc tương tự
- Lý do: private URL scheme, rủi ro bị Apple reject, user quyết bỏ

**(c) Xử lý notification từ app khác**
- Bỏ: suppress/silence notification của app khác trong Monk Mode
- Lý do: iOS Focus/Do Not Disturb (hệ thống) đã xử lý, không cần duplicate, FamilyControls pha 2 có khả năng nếu cần

### 4. Pha 1 Monk Mode làm gì

**Focus lock in-app:**
- Khóa UI FocusPlan vào 1 màn chính (focus session screen)
- Giấu/disable các navigation khác (tab bar, gesture swipe back)
- Nhắc user: "Bật Focus Mode / Do Not Disturb trên iPhone để ngăn chặn distraction từ các app khác"
- Kiểu "soft restriction" — không hard-lock thiết bị, chỉ lock app

**Tận dụng DND signal:**
- Level 3 badge (issue 017) sẵn detect DND status từ hệ thống
- Pha 1 Monk Mode dùng signal này để đề xuất kích hoạt (nếu user chưa bật)

### 5. Kích hoạt Monk Mode

**CẢ HAI — opt-in toggle + tự động theo focus session:**

1. **Opt-in toggle** trong Settings (`MonkModeSettings` screen)
   - Toggle "Bật Monk Mode"
   - Giải thích: khóa UI app, yêu cầu gõ lý do nếu tắt giữa chừng

2. **Tự động theo focus session**
   - Khi user bắt đầu focus session (Pomodoro, issue 006) VÀ đã opt-in, tự kích hoạt Monk Mode
   - Khi session kết thúc → tắt Monk Mode (không yêu cầu lý do — kết thúc đã hoàn thành)

### 6. Friction khi tắt giữa chừng — "Reflection gate"

**User phải gõ lý do dừng:**
- Popup: "Lý do dừng Monk Mode là gì?"
- Input: text field tối thiểu X ký tự (TBD, recommend 5–10)
- Heuristic local thuần **KHÔNG gọi Gemini/mạng**:
  - **Từ chối:** text vô nghĩa (1 ký tự, "ok", "abc", ký tự lặp "aaa"), quá ngắn
  - **Chấp nhận:** bất kỳ text có độ dài + suy nghĩ (heuristic: check dòng trên X ký tự + khác từng từ lặp lại)
  - **Không phán xét:** chỉ check có "suy nghĩ thật" hay không, KHÔNG đánh giá lý do đáng hay không ("lười", "muốn chơi game" cũng được)

### 7. Lưu lý do dừng

- Log: timestamp + lý do dừng
- Đưa vào daily reflection (issue 008) để user thấy pattern mất tập trung
- Format: structured log trong `UserDefaults` / Supabase (TBD khi implement)

### 8. Success criteria pha 1

**Metric: tỉ lệ focus session hoàn thành khi bật Monk Mode so với không bật**
- Cần telemetry local: track session start/end/interrupt per session
- KPI: completion rate ↑ when Monk Mode on vs off (ví dụ 85% vs 60%)
- Dùng để validate pha 1 hiệu quả trước khi nâng cấp pha 2

## Rủi ro còn mở

1. **Entitlement pha 2 phụ thuộc Apple**
   - Timeline: vài ngày–vài tuần
   - User tự nộp form qua developer portal
   - Nếu reject: cần alternative approach (vẫn giữ pha 1 focus lock)

2. **Heuristic local có thể bị lách**
   - Văn bản dài vô nghĩa (ví dụ copy-paste repeated string dài)
   - Chấp nhận ở pha 1, có thể nâng cấp Gemini ở pha sau

3. **Apple review với "hard to exit"**
   - Gate chỉ yêu cầu gõ lý do (soft restriction) → rủi ro thấp
   - Khác vs hard-lock (entitlement) → safer

## Hệ quả wiki

**Cần làm (không trong task này, leader điều phối sau):**
- Viết lại acceptance criteria issue 011 theo pha 1 quyết định
- Tạo thẻ/issue mới cho pha 2 (Screen Time entitlement implementation)
- Kiểm tra issue 017 — vẫn khớp (không đổi, vẫn né entitlement)

**Trong task này:** KHÔNG tự sửa issue — chỉ ghi Decision Log + log entry.

## Cross-references

- [[../issues/011-monk-mode-focus-session-blocking.md]] — cần refine acceptance criteria
- [[../issues/017-focus-mode-status-level-3-badge.md]] — vẫn giữ nguyên (pha 1 tận dụng DND signal)
- [[../issues/006-pomodoro-focus-session-timer.md]] — pha 1 Monk Mode kích hoạt tự động theo focus session
- [[../issues/008-daily-reflection-journal.md]] — lý do dừng feed vào daily reflection
