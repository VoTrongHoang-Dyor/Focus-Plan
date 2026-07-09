---
status: done
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Khung ứng dụng iOS native (Swift) tối thiểu cùng tích hợp auth qua Supabase (sign up / sign in / sign out, session persist). Đây là nền tảng bắt buộc cho mọi slice sau — sản phẩm ship multi-user nên auth phải có từ đầu, không phải retrofit sau.

## Acceptance criteria

- [x] User tạo tài khoản mới và đăng nhập được qua Supabase Auth từ app iOS.
- [x] Session được persist qua lần mở app tiếp theo (không phải đăng nhập lại mỗi lần).
- [x] Đăng xuất hoạt động và xoá session cục bộ.
- [x] Có màn hình app rỗng (empty state) sau khi đăng nhập, sẵn sàng cho các slice sau gắn vào.

## QA / verify (2026-07-03)

- Implement: SwiftUI + XcodeGen + SPM `supabase-swift` 2.48.0. Thư mục `FocusPlan/`, bundle id `com.votronghoang.focusplan`, iOS 17.
- Reviewer PASS vòng 2 (app code, commit `124352a`) + PASS commit QA harness `3e254ec`.
- QA end-to-end 5/5 PASS bằng XCUITest trên simulator iPhone 17 Pro + Supabase project thật (`** TEST SUCCEEDED **`). Ràng buộc môi trường: cần "Confirm email" TẮT (`mailer_autoconfirm: true`).

## Blocked by

None - can start immediately

## Decision Log sections addressed

- Đối tượng & mô hình sản phẩm
- Stack mobile
