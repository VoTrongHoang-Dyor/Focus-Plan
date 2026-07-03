---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Setting "Screen Time block" + "Monk Mode": opt-in trong Settings, khi bật thì chặn/hạn chế app gây xao nhãng, với friction cao cố tình để user khó tắt giữa chừng (tránh quyết định bốc đồng, pattern kiểu Freedom app). HITL vì cần review UX friction cụ thể trước khi build.

## Acceptance criteria

- [ ] User bật được Monk Mode từ Settings (opt-in, không bật mặc định).
- [ ] Có bước friction rõ ràng khi user cố tắt Monk Mode giữa chừng (cụ thể hoá sau khi review UX).
- [ ] Không dùng Screen Time entitlement thật của Apple cho MVP (rủi ro reject) — cần thống nhất cơ chế thay thế trong review.

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`

## Decision Log sections addressed

- Scope discipline framework MVP (Screen Time block + Monk Mode)
- Still open (liên quan UX friction chưa chốt)
