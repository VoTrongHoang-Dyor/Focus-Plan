# Addendum — UI Polish (issue 024) trên nền plan 2026-07-05

> Đọc CÙNG plan gốc `docs/superpowers/plans/2026-07-05-swift-ui-polish-flutter-parity.md`. Plan gốc viết TRƯỚC khi issue 021/022 land — addendum này chốt các điểm đã lệch so với codebase hiện tại. Khi mâu thuẫn, **addendum thắng plan gốc**.

## 1. Task 1 plan gốc — chỉ còn phần asset

- `Theme.swift` + `ThemeTests.swift`: **ĐÃ XONG** (commit trong plan issue 021). Bỏ qua Step 1–3 của Task 1.
- `FocusPlan/Resources/Assets.xcassets`: **ĐÃ TỒN TẠI** (issue 022 tạo, chứa `MascotBody.imageset`, `MascotArm.imageset`, `AppIcon.appiconset` slot rỗng). KHÔNG tạo lại/ghi đè catalog — chỉ **THÊM** vào catalog hiện có:
  - `BrandLogo.imageset` (copy `focus_plan_ui_demo/assets/images/logo.png`, universal 1x — Contents.json cùng format với MascotBody.imageset có sẵn).
  - `AccentColor.colorset` = #4F46E5.
- `project.yml` đã include `Resources/` — không sửa. Chỉ `xcodegen generate`.
- Commit riêng phần asset: `style(ui): add BrandLogo and AccentColor to asset catalog`

## 2. Task 3 plan gốc (Home) — codebase đã khác

HomeView hiện tại ĐÃ CÓ (từ 021/022, phải GIỮ NGUYÊN khi restyle):
- `MascotView(size: 64)` nằm trong HStack greeting (issue 022) — plan gốc viết "chừa chỗ cho mascot sau", nay mascot đã ở đó: restyle greeting block THÀNH 2 dòng ("Xin chào," + tên) **bên trong** HStack đang có mascot, không xoá/di chuyển mascot.
- Toolbar `topBarLeading` nút `home.alarm-button` + sheet `AlarmFormView` (issue 021) — giữ nguyên identifier + hành vi.
- `A11yID.Home.greetingText` vẫn phải gắn vào text chứa email (UITest cũ + AlarmFlowUITests assert).

## 3. Số test đã tăng

Plan gốc ghi "26 unit + 6 UITest" — con số cũ. Chuẩn hiện tại: **toàn bộ suite hiện có xanh, 0 fail 0 skip** (unit gồm thêm Theme/UserAlarmStore/UserAlarmPlanner; UITest gồm thêm `AlarmFlowUITests`). Task 6 verify theo tổng thực tế lúc chạy, không theo con số trong plan gốc/issue.

## 4. Ràng buộc bổ sung

- **KHÔNG đụng 2 commit CI local đang chờ push** (`11f5bc6`, `21aac3a` — issue 023 đang dừng HITL): không rebase/amend/reset, chỉ commit chồng lên; TUYỆT ĐỐI không push.
- AlarmFormView NGOÀI scope restyle (đã style bằng Theme từ 021) — plan gốc đã ghi, nhắc lại vì màn này giờ tồn tại thật.
- Evidence lưu đúng thư mục plan gốc: `docs/superpowers/plans/evidence/2026-07-05-ui-polish/`.

## Thứ tự thực thi cho issue 024

1. Asset (mục 1 addendum) → 2. Task 2 plan gốc (auth) → 3. Task 3 (home/tab, theo mục 2 addendum) → 4. Task 4 (task list/forms) → 5. Task 5 (habits) → 6. Task 6 (full suite + evidence 5 màn).
