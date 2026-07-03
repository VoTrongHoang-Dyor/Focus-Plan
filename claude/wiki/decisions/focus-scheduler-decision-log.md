---
status: Active
date: 2026-07-02
---

# Focus Scheduler App — Decision Log


App mobile chống trì hoãn: báo thức + reschedule tự động 9h sáng + streak/gamification. Dự án song song với Teacher AI (vẫn là dự án chính).

## Đối tượng & mô hình sản phẩm

- Sản phẩm ship ra ngoài (multi-user, auth, billing, compliance) — không phải personal tool.

## Cơ chế báo thức (core loop)

- Best-effort: local notification lặp lại nhiều lần (1-2 phút/lần, ~10 phút) + escalating tone. Không theo đuổi Critical Alerts entitlement (rủi ro Apple reject cao, không đáng effort).

## Trigger reschedule 9h sáng

- Supabase pg_cron + Edge Functions, server-side, theo timezone từng user → gọi reschedule logic → push qua APNs/FCM.

## Logic tìm slot trống

- Deterministic algorithm (rule-based: ưu tiên, energy-matching, buffer) do bạn viết. Gemini 2.0 Flash chỉ NLP parse input + sinh giải thích ngôn ngữ tự nhiên — không giao reasoning/constraint-solving cho LLM.

## Daily Reflection (bổ sung)

- Chỉ dùng dữ liệu khách quan (task done/missed/late, thời lượng Pomodoro thực tế) cho MVP. Journal/note văn bản tự do → defer sang v2.
- Free tier Gemini chấp nhận được, nhưng disclose rõ trong privacy policy việc Google có thể dùng data train model.
- Gộp chung 1 lần gọi với cron 9h sáng (reschedule + reflection cùng 1 Edge Function call), prompt phải tách rõ 2 phần output.

## Chi phí AI

- Gemini free tier cho beta/early users, chuyển paid tier khi scale (pass cost vào subscription).

## Scope discipline framework MVP

- Có: Seinfeld streak chain, Loss Aversion nhẹ (mất streak, không tiền thật), 6 Levels badge (đo qua Pomodoro data).
- Ẩn dưới dạng philosophy trong AI prompt/copy (không build UI riêng): Ngộ nhận Cân bằng/Tranh thủ, Info Diet, Fasting, Vietnam Airlines mindset.
- Screen Time block + Monk Mode: nằm trong Settings, opt-in, nhưng friction cao để tắt giữa chừng (tránh quyết định bốc đồng, pattern kiểu Freedom app).

## Stack mobile

- Native — Swift (iOS) trước để validate core loop, Kotlin (Android) sau khi có traction. Không dùng Expo dù đã quen từ Teacher AI.

## Thanh toán

- Stripe web-only subscription; app mobile chỉ check trạng thái, không có purchase flow trong app → né phí IAP 15-30%.

## Sequencing/bandwidth

- Teacher AI vẫn là dự án chính, không tạm dừng. App này build song song, iOS-first để giảm rủi ro trước khi cam kết Android.

## Still open

- Web stack framework, Supabase project share hay tách riêng với Teacher AI.
- Apple "external purchase" compliance UX chi tiết.
- Energy-matching algorithm cụ thể (có thể tái dùng logic từ /plan-my-day).
- Onboarding/philosophy delivery format.
- Pricing cụ thể.

## Assumptions đang đặt cược

- Apple sẽ không coi "check subscription status, không purchase flow" là vi phạm.
- Free tier Gemini đủ cho beta, kể cả khi spike đồng thời cùng múi giờ.
- Validate core loop trên iOS trước Android hợp lý — nhưng nếu target thị trường VN, tỷ trọng Android cao, đáng cân nhắc lại.

## Brainstorm thêm ý tưởng (bám sát constraint đã chốt)

### A. Khai thác sâu hơn Deterministic Algorithm (đã chốt là core, nên đầu tư đây trước)

1. Energy-matching có trọng số theo lịch sử thực tế, không chỉ rule tĩnh. Thay vì "buổi sáng = deep work" cố định, algorithm học từ Pomodoro completion rate theo khung giờ của từng user (vd 80% task 9-11h hoàn thành đúng hạn, 40% task 14-15h bị trễ) → tự điều chỉnh trọng số ưu tiên slot. Vẫn là deterministic (thống kê, không phải LLM reasoning). Tận dụng trực tiếp data đã bắt buộc phải lưu cho Daily Reflection, nên gần như miễn phí về effort bổ sung.
2. Buffer động theo "nợ lịch" (schedule debt). Nếu 1 ngày có quá nhiều task bị dời (vd >30%), algorithm tự nới buffer giữa các block ngày hôm sau thay vì nhồi nhét. Điểm khác biệt thực sự so với Motion (Motion nhồi lịch quá sát, gây stress ngược).
3. Conflict resolution có "giải thích" khi 2 task tranh 1 slot — Gemini (đúng vai NLP/copy đã chốt) sinh 1 câu giải thích ngắn tại sao task A thắng task B. Chi phí gần bằng 0 vì đã gọi Gemini sẵn cho phần giải thích reschedule.

### B. Mở rộng vòng game mechanics (nên làm, rẻ, đã có tiền lệ với 3 cái đã chọn)

1. Streak Insurance — cho phép "cứu" streak 1 lần/tuần nếu hoàn thành 1 task bù trong ngày (giống Duolingo streak freeze). Khớp đúng "Loss Aversion nhẹ" đã chọn nhưng giảm tỷ lệ user bỏ app vì phá streak 1 lần rồi nản. Rủi ro: làm lỏng quá thì mất tác dụng áp lực — giới hạn nghiêm (1 lần/tuần, không tích lũy).
2. Level 3 (tắt điện thoại) đo bằng tín hiệu gián tiếp thay vì Screen Time API thật — yêu cầu user bật Focus Mode/Do Not Disturb của hệ điều hành (iOS có API để app biết Focus Mode đang bật, dù không tự bật hộ được) làm điều kiện tính badge Level 3. Né được rủi ro Screen Time entitlement, vẫn giữ được cơ chế game.
3. Domino Preview (đặt tên tạm) — cuối ngày, hiện 1 màn hình duy nhất: "Nếu bạn hoàn thành task X ngày mai đúng giờ, streak Y sẽ đạt mốc Z". Áp dụng "chia nhỏ mục tiêu, dễ đạt phần thưởng nội tại" mà không cần build gì phức tạp — chỉ là 1 view tổng hợp từ data đã có.

### C. Ý tưởng nên HOÃN (ghi ra để không quên, nhưng đừng làm ở MVP — không đưa vào issues)

1. Social accountability (share streak với người khác, leaderboard bạn bè) — kéo theo bài toán multi-user relationship mới (friend system, privacy giữa users), ngoài scope "beta validate core loop".
2. AI phát hiện pattern trì hoãn và chủ động gợi ý thay đổi lịch trình dài hạn — quay lại đúng mâu thuẫn "Gemini không làm reasoning" đã né. Cần phân tích xu hướng dài hạn (không phải 1 ngày), đúng nghĩa reasoning chủ quan. Để dành sau khi core loop đã chạy ổn và có đủ data thật.
3. Voice input cho NLP task creation — thêm nguyên 1 tầng speech-to-text + latency UX risk, không phải bottleneck của core loop hiện tại.
