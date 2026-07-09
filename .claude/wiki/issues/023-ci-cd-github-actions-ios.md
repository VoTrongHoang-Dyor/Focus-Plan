---
status: done
---

## Parent PRD

`.claude/wiki/prd/focusplan-swift-mascot-mcp-web.md`

## What to build

Pipeline CI/CD GitHub Actions cho app iOS: mỗi push/PR chạy `xcodegen generate` + `xcodebuild test` (unit test luôn chạy; UITest tùy secrets Supabase — chốt ở plan) trên macOS runner với simulator; build artifact hướng tới TestFlight (bước ký/upload cần Apple Developer credentials — có thể tách giai đoạn sau khi user cấp).

**HITL:** cần user cấp secrets GitHub (Supabase URL/anon key cho UITest; về sau Apple credentials cho TestFlight) — coder dừng và báo leader khi tới bước cần secrets.

## Acceptance criteria

- [x] Workflow GitHub Actions chạy xanh trên push/PR: build + toàn bộ unit test pass trên CI (run 28792926607: 6m5s, unit+integration tests xanh).
- [x] UITest: gate rõ ràng (skip có chủ đích workflow_dispatch gate) + tài liệu `docs/ci.md` cách bật — không fail lặng lẽ ✓
- [x] Không secret nào bị commit; `Secrets.xcconfig` gitignored, secrets từ GitHub Secrets (read tại runtime) ✓
- [x] Kết quả test hiển thị rõ (artifact `unit.xcresult` + xcbeautify log per run) ✓

**Note:** TestFlight phase 2 (ký/upload release) chờ user cấp Apple Developer credentials — không block done (feature gate CI basic per design).

## Blocked by

None - can start immediately (song song với 019-022; phần TestFlight chờ user cấp credentials)

## User stories addressed

- User story 14 (CI chạy test mỗi push)
- User story 15 (build artifact hướng TestFlight)
- User story 16 (kết quả test rõ ràng cho reviewer)
