# CI/CD — FocusPlan iOS

Pipeline GitHub Actions: `.github/workflows/ios-ci.yml`. Runner: `macos-latest`.

## 1. Tổng quan pipeline

| Job | Trigger | Thời lượng ước tính | Artifact |
|---|---|---|---|
| `unit-tests` | Mỗi push vào `main` + mọi pull request | ~10-15 phút | `unit-test-results` (`unit.xcresult`) |
| `ui-tests` | Chỉ `workflow_dispatch` (bấm tay), input `run_uitests` (mặc định `true`) | ~30-60 phút | `ui-test-results` (`ui.xcresult`) |
| `archive` | Push vào `main` (sau khi `unit-tests` pass) | ~10-15 phút | `focusplan-archive` (`FocusPlan.xcarchive`, unsigned) |

`unit-tests` và `archive` là bắt buộc xanh cho mỗi push vào `main`. `ui-tests` là gate thủ công có chủ đích (xem mục 3) — không xuất hiện trong required checks của push/PR, không fail lặng lẽ vì được ghi rõ ở đây.

## 2. Secrets cần cấp (bắt buộc trước lần chạy đầu)

Vào GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**, thêm 2 secret:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Giá trị lấy từ file `FocusPlan/Config/Secrets.xcconfig` local (file này bị gitignore, không có trong repo) — **không paste giá trị thật vào tài liệu này hay bất kỳ file nào trong repo**. Cả 3 job đều tự sinh `Secrets.xcconfig` trên runner từ 2 secret này; nếu thiếu, job fail ngay với thông báo `::error::` rõ ràng thay vì lỗi build khó hiểu.

## 3. Cách chạy UITest trên CI

Job `ui-tests` **không** chạy tự động trên push/PR — đây là quyết định có chủ đích, không phải thiếu sót:

- UITest cần network Supabase thật (tạo user, đăng nhập, tạo task/habit/alarm), chạy chậm (~30-60 phút cho toàn bộ `FocusPlanUITests`).
- Có rủi ro flaky do dialog hệ thống (vd "Lưu mật khẩu?") khác nhau tuỳ ảnh runner GitHub theo thời gian.

Để chạy thủ công: tab **Actions** → chọn workflow **iOS CI** → **Run workflow** → giữ `run_uitests = true` (mặc định) → **Run workflow**.

## 4. Đọc kết quả test (không cần máy cá nhân)

- Log mỗi step được format qua `xcbeautify` — đọc trực tiếp trên Actions UI (mỗi step log có thể mở rộng), không cần tải gì thêm.
- Muốn drill-down chi tiết từng test case (stack trace, ảnh chụp khi UITest fail...): tải artifact tương ứng (`unit-test-results` / `ui-test-results`) ở cuối trang run, giải nén rồi mở file `.xcresult` bằng Xcode trên máy có Xcode.

## 5. Giai đoạn 2 — TestFlight (CHƯA làm, chờ user cấp credentials)

Job `archive` hiện chỉ build `.xcarchive` **unsigned** (`CODE_SIGNING_ALLOWED=NO`) và upload làm artifact — chứng minh Release build xanh, chưa ký và chưa upload lên App Store Connect/TestFlight.

Để hoàn thiện giai đoạn 2, cần user cấp thêm:

- **App Store Connect API key**: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (tải từ App Store Connect → Users and Access → Keys).
- **Signing**: Apple Distribution certificate + provisioning profile tương ứng bundle id `com.votronghoang.focusplan` — hoặc chuyển sang ký tự động qua `fastlane match` (đơn giản hoá quản lý certificate/profile giữa các máy/CI).

Khi có đủ 2 mục trên → mở issue riêng cho việc ký + upload TestFlight, không gộp vào issue 023.
