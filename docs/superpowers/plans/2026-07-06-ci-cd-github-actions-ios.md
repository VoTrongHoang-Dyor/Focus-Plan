# CI/CD GitHub Actions iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pipeline GitHub Actions cho FocusPlan iOS: mỗi push/PR chạy build + unit test; UITest gate thủ công rõ ràng; artifact Release archive (unsigned) hướng tới TestFlight — issue 023.

**Architecture:** 1 workflow `.github/workflows/ios-ci.yml` với 3 job: `unit-tests` (mỗi push/PR — bắt buộc xanh), `ui-tests` (chỉ `workflow_dispatch` — gate chủ đích, có tài liệu cách bật), `archive` (push main — xcarchive unsigned làm artifact; ký/upload TestFlight là giai đoạn 2 chờ Apple credentials). `Secrets.xcconfig` (gitignored) được SINH trên runner từ GitHub Secrets. Kết quả test upload dạng `.xcresult` artifact + log xcbeautify đọc được ngay trên UI Actions.

**Tech Stack:** GitHub Actions (runner `macos-latest`), XcodeGen + xcbeautify (brew), xcodebuild, actionlint (lint local).

## Bối cảnh codebase (đã khảo sát — coder không cần tìm lại)

- Remote: `https://github.com/VoTrongHoang-Dyor/Focus-Plan.git`, branch `main`. Chưa có `.github/workflows/`.
- `FocusPlan/Config/Secrets.xcconfig` bị **gitignore** (đúng); bản mẫu `Secrets.example.xcconfig` được track. App đọc `SUPABASE_URL`/`SUPABASE_ANON_KEY` qua Info.plist ← xcconfig. **Quirk xcconfig:** `//` là comment nên URL phải escape thành `https:/$()/...` (xem file example).
- UITest (`FocusPlan/UITests/*.swift`) hardcode sẵn Supabase URL + anon key public trong file test → UITest KHÔNG cần secret riêng, chỉ cần app build được (tức cần Secrets.xcconfig) + network + simulator.
- `SupabaseConfigTests` (unit) đọc giá trị thật từ Info.plist → secrets trên CI phải là giá trị THẬT, không placeholder.
- Test đích local hiện dùng simulator "iPhone 17 Pro" — trên runner GitHub tên device khác nhau theo image → workflow phải pick simulator ĐỘNG, không hardcode tên.

## Quyết định chốt tại plan (issue 023 để mở "chốt ở plan")

1. **UITest gate:** job `ui-tests` chỉ chạy khi `workflow_dispatch` (bấm tay trên tab Actions, input `run_uitests` mặc định true). KHÔNG chạy trên push/PR (chậm ~30-60', phụ thuộc network Supabase thật + springboard dialog — flaky risk). Gate này là "skip có chủ đích + có tài liệu" đúng acceptance 2, không fail lặng lẽ (job không xuất hiện trong required checks của push/PR).
2. **Secrets cần user cấp (HITL):** `SUPABASE_URL`, `SUPABASE_ANON_KEY` vào GitHub Secrets của repo. Workflow fail-fast với `::error::` rõ ràng nếu thiếu — không fail lặng lẽ.
3. **TestFlight = giai đoạn 2, KHÔNG làm trong issue này:** job `archive` chỉ build Release `.xcarchive` với `CODE_SIGNING_ALLOWED=NO` và upload artifact (chứng minh build-release xanh, "hướng tới TestFlight"). Ký + upload cần App Store Connect API key (ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_P8) + signing certificate — ghi thành mục "Giai đoạn 2" trong docs, chờ user cấp.
4. **Kết quả test đọc được không cần máy cá nhân:** log qua `xcbeautify` (đọc ngay trên Actions UI) + upload `.xcresult` artifact (tải về mở bằng Xcode khi cần drill-down).
5. **HITL checkpoint:** hoàn thành Task 1–3 + lint local → coder COMMIT LOCAL rồi DỪNG, báo leader (KHÔNG tự push). Sau khi user cấp secrets + duyệt push, mới chạy Task 4 (verify CI xanh thật) rồi gửi reviewer.

## Global Constraints

- KHÔNG commit bất kỳ secret nào (URL/key thật chỉ nằm trong GitHub Secrets; file sinh ra trên runner). `Secrets.xcconfig` local KHÔNG được đụng.
- KHÔNG sửa `FocusPlan/project.yml`, code app, hay test hiện có — issue này chỉ thêm workflow + docs.
- Workflow YAML phải pass `actionlint` local trước khi commit.
- Mọi job có `timeout-minutes` (né treo runner) và `concurrency` cancel-in-progress theo ref.
- Commit message prefix `ci:` / `docs(ci):`.

---

### Task 1: Workflow `ios-ci.yml` — job unit-tests + ui-tests + archive

**Files:**
- Create: `.github/workflows/ios-ci.yml`

**Interfaces:**
- Consumes: GitHub Secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY` (user cấp ở Task 4).
- Produces: artifacts `unit-test-results` (`unit.xcresult`), `ui-test-results` (`ui.xcresult`), `focusplan-archive` (`FocusPlan.xcarchive`). Docs Task 2 tham chiếu các tên job/artifact này.

- [ ] **Step 1: Viết workflow:**

```yaml
name: iOS CI

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
    inputs:
      run_uitests:
        description: "Chạy UITest (cần network Supabase thật, ~30-60 phút)"
        type: boolean
        default: true

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  unit-tests:
    name: Build + Unit tests
    runs-on: macos-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4

      - name: Select latest stable Xcode
        run: |
          XCODE=$(ls -d /Applications/Xcode*.app | sort -V | tail -1)
          echo "Using $XCODE"
          sudo xcode-select -s "$XCODE"

      - name: Install tools
        run: brew install xcodegen xcbeautify

      - name: Generate Secrets.xcconfig from GitHub Secrets
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
            echo "::error::Thiếu SUPABASE_URL / SUPABASE_ANON_KEY trong GitHub Secrets (Settings > Secrets and variables > Actions)."
            exit 1
          fi
          # xcconfig coi "//" là comment -> escape "https://" thành "https:/$()/" (xem Secrets.example.xcconfig)
          ESCAPED_URL=$(printf '%s' "$SUPABASE_URL" | sed 's|://|:/$()/|')
          printf 'SUPABASE_URL = %s\nSUPABASE_ANON_KEY = %s\n' "$ESCAPED_URL" "$SUPABASE_ANON_KEY" > FocusPlan/Config/Secrets.xcconfig

      - name: Generate Xcode project
        working-directory: FocusPlan
        run: xcodegen generate

      - name: Pick available iPhone simulator
        id: sim
        run: |
          DEVICE=$(xcrun simctl list devices available | awk -F' \\(' '/iPhone/{print $1; exit}' | sed 's/^ *//')
          if [ -z "$DEVICE" ]; then echo "::error::Không tìm thấy iPhone simulator trên runner."; exit 1; fi
          echo "device=$DEVICE" >> "$GITHUB_OUTPUT"
          echo "Simulator: $DEVICE"

      - name: Run unit tests
        working-directory: FocusPlan
        run: |
          set -o pipefail
          xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
            -destination "platform=iOS Simulator,name=${{ steps.sim.outputs.device }}" \
            -resultBundlePath TestResults/unit.xcresult \
            test -only-testing:FocusPlanTests | xcbeautify

      - name: Upload unit test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: unit-test-results
          path: FocusPlan/TestResults/unit.xcresult

  ui-tests:
    name: UITests (manual gate — workflow_dispatch)
    if: github.event_name == 'workflow_dispatch' && inputs.run_uitests
    runs-on: macos-latest
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v4

      - name: Select latest stable Xcode
        run: |
          XCODE=$(ls -d /Applications/Xcode*.app | sort -V | tail -1)
          sudo xcode-select -s "$XCODE"

      - name: Install tools
        run: brew install xcodegen xcbeautify

      - name: Generate Secrets.xcconfig from GitHub Secrets
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
            echo "::error::Thiếu SUPABASE_URL / SUPABASE_ANON_KEY trong GitHub Secrets."
            exit 1
          fi
          ESCAPED_URL=$(printf '%s' "$SUPABASE_URL" | sed 's|://|:/$()/|')
          printf 'SUPABASE_URL = %s\nSUPABASE_ANON_KEY = %s\n' "$ESCAPED_URL" "$SUPABASE_ANON_KEY" > FocusPlan/Config/Secrets.xcconfig

      - name: Generate Xcode project
        working-directory: FocusPlan
        run: xcodegen generate

      - name: Pick available iPhone simulator
        id: sim
        run: |
          DEVICE=$(xcrun simctl list devices available | awk -F' \\(' '/iPhone/{print $1; exit}' | sed 's/^ *//')
          if [ -z "$DEVICE" ]; then echo "::error::Không tìm thấy iPhone simulator trên runner."; exit 1; fi
          echo "device=$DEVICE" >> "$GITHUB_OUTPUT"

      - name: Run UI tests
        working-directory: FocusPlan
        run: |
          set -o pipefail
          xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
            -destination "platform=iOS Simulator,name=${{ steps.sim.outputs.device }}" \
            -resultBundlePath TestResults/ui.xcresult \
            test -only-testing:FocusPlanUITests | xcbeautify

      - name: Upload UI test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ui-test-results
          path: FocusPlan/TestResults/ui.xcresult

  archive:
    name: Release archive (unsigned, hướng TestFlight)
    runs-on: macos-latest
    timeout-minutes: 45
    needs: unit-tests
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      - name: Select latest stable Xcode
        run: |
          XCODE=$(ls -d /Applications/Xcode*.app | sort -V | tail -1)
          sudo xcode-select -s "$XCODE"

      - name: Install tools
        run: brew install xcodegen

      - name: Generate Secrets.xcconfig from GitHub Secrets
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
            echo "::error::Thiếu SUPABASE_URL / SUPABASE_ANON_KEY trong GitHub Secrets."
            exit 1
          fi
          ESCAPED_URL=$(printf '%s' "$SUPABASE_URL" | sed 's|://|:/$()/|')
          printf 'SUPABASE_URL = %s\nSUPABASE_ANON_KEY = %s\n' "$ESCAPED_URL" "$SUPABASE_ANON_KEY" > FocusPlan/Config/Secrets.xcconfig

      - name: Generate Xcode project
        working-directory: FocusPlan
        run: xcodegen generate

      - name: Build Release archive (unsigned)
        working-directory: FocusPlan
        run: |
          set -o pipefail
          xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
            -configuration Release -destination 'generic/platform=iOS' \
            -archivePath build/FocusPlan.xcarchive \
            CODE_SIGNING_ALLOWED=NO archive

      - name: Upload archive artifact
        uses: actions/upload-artifact@v4
        with:
          name: focusplan-archive
          path: FocusPlan/build/FocusPlan.xcarchive
```

- [ ] **Step 2: Lint local** — `brew install actionlint` (nếu chưa có) rồi `actionlint .github/workflows/ios-ci.yml`. Expected: 0 error.
- [ ] **Step 3: Smoke-test script sinh Secrets local** (KHÔNG ghi đè file thật) — chạy đoạn sed với input giả vào file tạm `/tmp/test-secrets.xcconfig`, xác nhận output có dạng `SUPABASE_URL = https:/$()/xxx.supabase.co`; xoá file tạm.
- [ ] **Step 4: Commit** — `git commit -m "ci: GitHub Actions pipeline (unit tests on push/PR, gated UITests, unsigned release archive)"`

---

### Task 2: Tài liệu CI — `docs/ci.md`

**Files:**
- Create: `docs/ci.md`

- [ ] **Step 1: Viết docs** gồm đúng các mục sau (nội dung theo quyết định đã chốt ở đầu plan):
  1. **Tổng quan pipeline**: bảng 3 job (`unit-tests` push/PR, `ui-tests` workflow_dispatch, `archive` push main) — trigger, thời lượng ước tính, artifact tương ứng.
  2. **Secrets cần cấp** (bước bắt buộc trước lần chạy đầu): `SUPABASE_URL`, `SUPABASE_ANON_KEY` — đường dẫn GitHub Settings → Secrets and variables → Actions; ghi rõ giá trị lấy từ `FocusPlan/Config/Secrets.xcconfig` local (KHÔNG paste giá trị thật vào docs).
  3. **Cách chạy UITest trên CI**: tab Actions → iOS CI → Run workflow → chọn `run_uitests` — kèm lý do gate (chậm, network Supabase thật, flaky risk springboard dialog).
  4. **Đọc kết quả test**: log xcbeautify trực tiếp trên Actions UI; tải artifact `.xcresult` mở bằng Xcode để drill-down từng test.
  5. **Giai đoạn 2 — TestFlight (CHƯA làm, chờ user cấp credentials)**: liệt kê chính xác thứ cần: App Store Connect API key (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`), Apple Distribution certificate + provisioning profile (hoặc chuyển signing tự động qua fastlane match). Khi có đủ → mở issue mới, không nhét vào issue 023.
- [ ] **Step 2: Commit** — `git commit -m "docs(ci): pipeline overview, required secrets, UITest gate, TestFlight phase 2"`

---

### Task 3: HITL checkpoint — DỪNG, báo leader (KHÔNG push)

- [ ] **Step 1:** Xác nhận trạng thái: 2 commit local (Task 1 + 2), `actionlint` pass, không secret nào trong diff (`git diff origin/main --stat` + tự soát).
- [ ] **Step 2:** SendMessage cho leader, nêu rõ: (a) đã xong workflow + docs, chờ user làm 2 việc — thêm 2 secrets `SUPABASE_URL`/`SUPABASE_ANON_KEY` vào GitHub repo, và duyệt push lên `main`; (b) sau khi có 2 thứ đó mới verify được acceptance "workflow chạy xanh". KHÔNG tự push.

---

### Task 4: Verify CI xanh thật (chạy SAU khi user cấp secrets + duyệt push)

- [ ] **Step 1: Push** — `git push origin main` (chỉ sau khi leader xác nhận user đã duyệt).
- [ ] **Step 2: Theo dõi run** — `gh run watch` (hoặc `gh run list --workflow=ios-ci.yml` + `gh run view <id>`). Expected: job `unit-tests` PASS, job `archive` PASS, artifact `unit-test-results` + `focusplan-archive` xuất hiện.
- [ ] **Step 3: Trigger UITest gate 1 lần để chứng minh acceptance 2** — `gh workflow run ios-ci.yml -f run_uitests=true` rồi `gh run watch`. Expected: job `ui-tests` PASS (nếu fail vì flaky simulator/network → ghi nhận nguyên nhân cụ thể, retry 1 lần; fail bền vững thì báo leader kèm log, KHÔNG hạ gate).
- [ ] **Step 4:** Chụp/ghi link run xanh vào báo cáo gửi reviewer.

---

## Acceptance criteria mapping (issue 023)

| Criteria | Task |
|---|---|
| Workflow chạy xanh trên push/PR: build + unit test pass trên CI | Task 1 (job unit-tests) + Task 4 (verify thật) |
| UITest chạy xanh trên CI hoặc gate rõ ràng + tài liệu cách bật, không fail lặng lẽ | Task 1 (job ui-tests, workflow_dispatch) + Task 2 (docs mục 3) + Task 4 Step 3 |
| Không secret commit vào repo; đọc từ GitHub Secrets | Task 1 (sinh Secrets.xcconfig trên runner, fail-fast khi thiếu) + Task 3 Step 1 (soát diff) |
| Kết quả test đọc được không cần máy cá nhân | Task 1 (xcbeautify log + .xcresult artifact) + Task 2 (docs mục 4) |
