---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Khung ứng dụng iOS native (Swift) tối thiểu cùng tích hợp auth qua Supabase (sign up / sign in / sign out, session persist). Đây là nền tảng bắt buộc cho mọi slice sau — sản phẩm ship multi-user nên auth phải có từ đầu, không phải retrofit sau.

## Acceptance criteria

- [ ] User tạo tài khoản mới và đăng nhập được qua Supabase Auth từ app iOS.
- [ ] Session được persist qua lần mở app tiếp theo (không phải đăng nhập lại mỗi lần).
- [ ] Đăng xuất hoạt động và xoá session cục bộ.
- [ ] Có màn hình app rỗng (empty state) sau khi đăng nhập, sẵn sàng cho các slice sau gắn vào.

## Blocked by

None - can start immediately

## Decision Log sections addressed

- Đối tượng & mô hình sản phẩm
- Stack mobile
