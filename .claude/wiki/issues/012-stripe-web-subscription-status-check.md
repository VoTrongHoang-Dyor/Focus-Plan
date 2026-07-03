---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Subscription qua Stripe trên web; app mobile chỉ check trạng thái subscription (không có purchase flow trong app) để né phí IAP 15-30%. HITL vì cần review compliance "external purchase" của Apple trước khi build.

## Acceptance criteria

- [ ] App đọc được trạng thái subscription hiện tại của user (active/expired) từ backend.
- [ ] App không có bất kỳ UI/flow mua hàng nào bên trong (mọi thanh toán diễn ra trên web qua Stripe).
- [ ] Có đường dẫn rõ ràng hướng user ra web để subscribe/renew, tuân thủ đúng ràng buộc "external purchase" của Apple (chi tiết UX cần review — xem Still open trong Decision Log).

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`

## Decision Log sections addressed

- Thanh toán
- Still open (Apple external purchase compliance UX)
