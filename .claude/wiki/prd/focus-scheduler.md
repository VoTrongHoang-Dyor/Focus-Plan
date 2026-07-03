---
status: Active
date: 2026-07-02
---

# Focus Plan App — PRD

## Problem Statement

Người dùng muốn xây dựng kỷ luật và giảm trì hoãn nhưng lịch trình cá nhân liên tục bị phá vỡ: task bị dời, không ai nhắc lại đủ mạnh, và không có phản hồi khách quan nào cho họ biết họ thực sự đang làm tốt hay tệ. Các app lịch hiện có (vd Motion) nhồi lịch quá sát gây stress ngược, hoặc dựa vào ý chí tự giác mà không tạo áp lực/động lực đủ để duy trì thói quen.

## Solution

Một app mobile iOS-first (Swift native), multi-user, ship ra ngoài công khai, với:

- Nhập task bằng ngôn ngữ tự nhiên, Gemini 2.0 Flash chỉ làm NLP parsing + copy, không làm reasoning lịch trình.
- Deterministic scheduling engine (rule-based) tự xếp task vào slot rảnh, có energy-matching, buffer, và buffer động theo "nợ lịch".
- Báo thức local notification lặp lại, tăng dần độ khẩn, best-effort (không cần Critical Alerts entitlement).
- Reschedule tự động mỗi 9h sáng theo timezone user (Supabase pg_cron + Edge Function) kèm Daily Reflection dựa trên dữ liệu khách quan.
- Gamification nhẹ: streak, loss aversion (không tiền thật), 6 levels badge, streak insurance, Domino Preview cuối ngày.
- Monetization: Stripe subscription web-only, app chỉ check trạng thái — né phí IAP.
- Monk Mode/Screen Time setting opt-in, friction cao để tắt giữa chừng.
- Habit/Routine tracking: module riêng cho việc lặp lại hàng ngày theo giờ cố định (vd thiền, tập thể dục), tách biệt khỏi task đơn lẻ do Scheduling Engine xếp lịch.
- Pomodoro timer UI: màn hình đếm giờ focus session (start/stop/pause), là nguồn dữ liệu thực tế cho Gamification (badge Level 3 hiện đang giả định "dữ liệu Pomodoro" mà chưa có module nào tạo ra).

## User Stories

1. As a user, I want to create an account and sign in securely, so that my tasks and progress are private to me.
2. As a user, I want my session to persist between app opens, so that I don't have to log in every time.
3. As a user, I want to create a task by typing a natural sentence, so that I don't have to fill out a rigid form.
4. As a user, I want to review and correct a task the app misunderstood before it's saved, so that my schedule stays accurate.
5. As a user, I want to edit or delete a task I created, so that I can fix mistakes or remove tasks that are no longer relevant.
6. As a user, I want the app to automatically slot my tasks into free times in my day, so that I don't have to manually plan my schedule.
7. As a user, I want tasks that need deep focus scheduled at the times I'm historically most productive, so that I'm more likely to complete them.
8. As a user, I want buffer time between scheduled tasks, so that my day doesn't feel impossibly packed.
9. As a user, I want to receive a repeating, escalating alarm when a scheduled task starts, so that I'm hard to ignore even if I miss the first notification.
10. As a user, I want the alarm to stop once I acknowledge the task, so that I'm not spammed after I've responded.
11. As a user, I want my schedule to automatically re-plan every morning at 9am in my own timezone, so that yesterday's missed tasks don't just disappear.
12. As a user, I want to be notified when my schedule has been rescheduled, so that I know what changed.
13. As a user, I want a daily reflection summary of what I completed, missed, or did late, so that I can see my actual behavior patterns.
14. As a user, I want the reflection to be based only on objective data I generated, so that I trust it's not making things up about me.
15. As a user, I want to know how my data is used by the AI provider, so that I can make an informed privacy decision.
16. As a user, I want to build a visible streak of days I stay on track, so that I have a motivating reason to keep going.
17. As a user, I want to feel the loss when I break my streak, so that I'm nudged to avoid missing days, without risking real money.
18. As a user, I want to progress through levels based on my actual focus behavior (Pomodoro data), so that my long-term effort is recognized.
19. As a user, I want to "insure" my streak once a week by completing a make-up task, so that one bad day doesn't erase my progress and make me quit.
20. As a user, I want Level 3 progress tracked through my phone's Focus Mode/Do Not Disturb status, so that I get credit for genuinely disconnecting without the app needing invasive screen time permissions.
21. As a user, I want to opt into a high-friction "Monk Mode" that blocks distracting apps, so that I can commit to focus sessions without being one impulsive tap away from quitting.
22. As a user, I want Monk Mode to be something I explicitly opt into, so that the app doesn't restrict my phone without my consent.
23. As a user, I want an end-of-day preview showing what streak milestone I'll hit if I complete tomorrow's first task on time, so that I have a concrete, motivating reason to start strong tomorrow.
24. As a user, I want a short natural-language explanation when two of my tasks compete for the same time slot, so that I understand why the schedule picked one over the other.
25. As a user, I want the app's tone and messaging to subtly reinforce productivity philosophy (avoiding the "balance" fallacy, information diet, focus mindset), so that the app feels like more than a bare utility, without cluttering the UI with extra screens.
26. As a user, when I have a run of missed/rescheduled tasks, I want the app to give me more breathing room the next day instead of cramming, so that I don't spiral into a burnout loop.
27. As a user, I want to subscribe to the app via a web page, so that I get the best price without an app store markup.
28. As a user, I want the app to recognize my active subscription automatically, so that I don't have to manage payment inside the app.
29. As a user, I want to be clearly directed to the web to manage my subscription, so that I'm not confused about where to pay.
30. As a beta user, I want the AI features to run on a free tier without me being charged, so that I can try the product risk-free.
31. As the developer, I want the scheduling engine to be a pure, deterministic function I can test with fixed inputs, so that I can trust it without flaky AI-dependent behavior.
32. As the developer, I want Gemini scoped strictly to NLP parsing and copy generation, so that the core scheduling logic never depends on non-deterministic LLM reasoning.
33. As a user, I want to set up recurring habits with a fixed time each day (e.g. meditation, exercise), so that I can track routines separately from one-off tasks without them competing for scheduling logic.
34. As a user, I want a visible Pomodoro timer with start/stop/pause, so that my actual focus sessions generate the data my gamification badges are based on, instead of that data being assumed but never captured.

## Implementation Decisions

- **Auth & App Shell**: Native iOS (Swift) client; Supabase Auth cho signup/signin/session persistence. Android (Kotlin) hoãn đến khi iOS validate được core loop.
- **Task Capture module**: Nhận input ngôn ngữ tự nhiên, gọi Gemini 2.0 Flash chỉ để NLP parse thành task có cấu trúc (tên, thời lượng ước tính, priority, deadline). User xác nhận/sửa trước khi lưu. Không giao reasoning lịch trình cho LLM.
- **Scheduling Engine module (deep module)**: Deterministic, rule-based, pure function — task list + dữ liệu lịch sử + danh sách busy-block từ habit vào, schedule ra. Trách nhiệm: sắp xếp theo priority, energy-matching (rule tĩnh ban đầu, sau nâng cấp trọng số theo lịch sử completion rate), chèn buffer, nới buffer theo "nợ lịch" (>30% task bị dời), phát hiện xung đột slot, tránh xếp task đè lên khung giờ habit đã cố định.
- **Habit/Routine Tracking module**: Độc lập với Scheduling Engine — checklist giờ cố định do user tự đặt, không qua thuật toán xếp lịch. Điểm tích hợp duy nhất: xuất danh sách khung giờ habit ra làm busy-block input cho Scheduling Engine. UI cụ thể của checklist chờ review (HITL).
- **Pomodoro Timer module**: Màn hình đếm giờ focus session (start/stop/pause), chạy nền khi app minimize/khoá màn hình, kết thúc phiên báo qua local notification — tái dùng hạ tầng của Alarm/Notification module, không xây cơ chế thông báo mới. Là nguồn dữ liệu Pomodoro thực tế cho Gamification module (badge Level 3, streak tính theo Pomodoro). Độ dài phiên có cấu hình được hay cố định 25 phút — chờ quyết định.
- **Alarm/Notification module**: Local notification iOS, lặp lại 1-2 phút/lần trong ~10 phút, tone tăng dần, best-effort (không dùng Critical Alerts entitlement). Dừng khi user tương tác.
- **Reschedule Cron module**: Supabase pg_cron + Edge Function, chạy 9h sáng theo timezone từng user. Gọi Scheduling Engine, push kết quả qua APNs (iOS) — interface FCM để sẵn cho Android.
- **Daily Reflection module**: Chạy trong cùng lần gọi Edge Function với reschedule cron. Tổng hợp dữ liệu khách quan (done/missed/late, thời lượng Pomodoro thực tế). Một lần gọi Gemini sinh 2 phần output tách biệt rõ ràng: giải thích reschedule + tóm tắt reflection.
- **Conflict Explanation**: Khi Scheduling Engine phát hiện xung đột slot, ghi lại task thắng/thua + lý do; Gemini sinh giải thích ngắn để hiển thị — dùng chung path Gemini đã có cho giải thích reschedule.
- **Gamification module (deep module)**: Tính streak (Seinfeld chain), feedback Loss Aversion (không tiền thật), 6 levels badge từ dữ liệu Pomodoro, Streak Insurance (1 lần cứu/tuần, không tích luỹ), Level 3 badge từ tín hiệu Focus Mode/DND của hệ điều hành (không dùng Screen Time entitlement).
- **Domino Preview**: Màn hình cuối ngày tổng hợp thuần từ dữ liệu streak/task đã có — không thêm nguồn dữ liệu mới.
- **Monk Mode / Screen Time Setting**: Opt-in, nằm trong Settings, cố tình friction cao để tắt giữa chừng. Cơ chế friction cụ thể chờ review UX (HITL).
- **Subscription module**: Stripe subscription quản lý hoàn toàn trên web. App mobile chỉ đọc trạng thái subscription từ backend — không có purchase flow trong app, né phí IAP. UX tuân thủ "external purchase" của Apple chờ review (HITL).
- **AI Copy/Philosophy layer**: Chỉ tinh chỉnh ở tầng prompt (không có UI riêng) để lồng ghép các philosophy đã chọn vào copy reschedule/reflection.

Cross-cutting:

- Backend: Supabase (Postgres + pg_cron + Edge Functions + Auth). Quyết định còn mở: share hay tách riêng Supabase project với Teacher AI.
- AI: Gemini 2.0 Flash, free tier cho beta/early users; chuyển paid tier khi scale (pass cost vào subscription). Privacy policy phải disclose việc Google có thể dùng data free-tier để train model.
- Hai issue HITL (Monk Mode friction UX, Stripe/Apple compliance UX) cần review thiết kế/compliance trước khi build — không tự quyết một mình.

## Testing Decisions

- Test tốt ở đây nghĩa là **integration-style qua public interface** của module — input vào, output ra — không mock collaborator nội bộ, theo đúng skill `tdd` của repo này (`.claude/skills/tdd/tests.md`): test WHAT module làm, không phải HOW; sống sót qua refactor nội bộ.
- Module cần test (chỉ deep module thuần logic, theo phạm vi đã chọn):
  - **Scheduling Engine** (sắp xếp priority, energy-matching tĩnh + có trọng số lịch sử, chèn buffer, nới buffer theo nợ lịch, phát hiện xung đột, tránh đè lên busy-block từ habit) — fixture task-list + dữ liệu lịch sử + busy-block cố định vào, schedule chính xác ra.
  - **Gamification core** (chuyển trạng thái streak chain, ngưỡng level badge, điều kiện/giới hạn streak insurance) — fixture lịch sử task/Pomodoro cố định vào, trạng thái streak/badge chính xác ra.
- Rõ ràng ngoài phạm vi test tự động ở giai đoạn này: luồng UI, thời điểm gửi notification (phụ thuộc device/OS), chất lượng output Gemini (non-deterministic, đánh giá thủ công), phần nối dây Edge Function/cron (test thủ công trên Supabase project thật trong giai đoạn beta), Habit/Routine Tracking UI (checklist thuần, không phải deep logic), Pomodoro Timer UI (timer/notification, đánh giá thủ công trên device thật).
- Prior art: `.claude/skills/tdd/tests.md` trong repo này đã ghi lại pattern test tốt/xấu (integration-style vs. implementation-detail) — áp dụng cho 2 module trên.

## Out of Scope

- App Android (Kotlin) — hoãn đến khi iOS validate được core loop và có traction.
- Reflection dạng journal/note tự do — defer sang v2; MVP chỉ dùng dữ liệu khách quan.
- Critical Alerts entitlement cho hệ thống báo thức — không theo đuổi (rủi ro Apple reject cao, không đáng effort cho một hệ thống best-effort).
- Screen Time API thật — không dùng ở bất kỳ đâu; Monk Mode và Level 3 badge dùng setting opt-in / tín hiệu Focus Mode thay thế.
- Purchase flow trong app — subscription chỉ qua web (Stripe).
- Social accountability (share streak, leaderboard bạn bè) — hoãn; kéo theo bài toán multi-user relationship/privacy mới ngoài scope beta.
- AI chủ động phát hiện pattern trì hoãn dài hạn và gợi ý thay đổi lịch trình — hoãn; đòi hỏi LLM reasoning thật sự trên xu hướng dài hạn, mâu thuẫn với quyết định "Gemini chỉ NLP/copy". Cân nhắc lại sau khi core loop chạy đủ lâu để có data thật.
- Voice input cho task creation — không phải bottleneck của core loop; thêm tầng speech-to-text và rủi ro latency không đáng đánh đổi.

## Further Notes

- App này chạy song song với Teacher AI (vẫn là dự án chính) — sequencing/bandwidth chia theo đó, iOS-first để giảm rủi ro trước khi cam kết Android.
- **Rebrand & mục tiêu kép (2026-07-03)**: Dự án đổi định vị thành "Focus Plan", đồng thời phục vụ 2 mục tiêu song song, không cái nào là phụ: (a) sản phẩm chạy thật như mô tả ở trên, và (b) case study quy trình làm việc — dùng bộ skills cá nhân (`.claude/skills/`) và bộ não thứ 2 (`.claude/wiki/`) của repo này để demo cho nhà tuyển dụng/khách hàng tiềm năng. "Done" cho mục tiêu (b) nghĩa là: app chạy được thật (TestFlight/demo video) + wiki/PRD/decision log đủ sạch để đọc công khai. Không có deadline cứng — chấp nhận rủi ro tiến độ kéo dài để đổi lấy scope đầy đủ hơn.
- **Tác động tới 16 issue hiện có**: `.claude/wiki/issues/001-*.md` đến `016-*.md` sẽ cần viết lại/bổ sung ở bước `prd-to-issues` tiếp theo, vì 2 module mới (Habit/Routine Tracking, Pomodoro Timer) chèn vào core loop — Habit cần tích hợp busy-block với Scheduling Engine trước khi module đó coi là hoàn chỉnh; Pomodoro Timer cần có trước Gamification core (issue 007) để có dữ liệu thật thay vì giả định.
- Câu hỏi còn mở (xem Decision Log mục "Still open" và section rebrand): framework stack web cho trang subscription Stripe, share hay tách Supabase project với Teacher AI, UX compliance "external purchase" của Apple chi tiết, format onboarding/philosophy delivery, pricing cụ thể, UI cụ thể cho Habit checklist, độ ưu tiên implement Habit vs. Pomodoro Timer, độ dài phiên Pomodoro có cấu hình được không.
- Toàn bộ bối cảnh và lý do cho từng quyết định ở trên nằm tại `.claude/wiki/decisions/focus-scheduler-decision-log.md`; 16 issue triển khai hiện có đã chia PRD (bản trước rebrand) thành các vertical slice làm độc lập được, sắp theo dependency — thứ tự này cần rà soát lại sau rebrand.
- Theo Second Brain schema của repo (`CLAUDE.md` §7), PRD này giờ hiển thị qua Dataview query "Active PRD" trong Obsidian (vault = `.claude/wiki/`). Upload lên NotebookLM để tổng hợp thêm là bước thủ công, người dùng tự làm.
