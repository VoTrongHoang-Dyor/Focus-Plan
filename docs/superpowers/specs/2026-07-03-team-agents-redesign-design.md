# Thiết kế: Cập nhật Team Agents cho dự án codebase (leader/coder/reviewer/librarian)

## Bối cảnh

Team hiện tại (`claude/agents/{leader,coder,reviewer,librarian}.md` + `claude/commands/team.md`) được thiết kế cho dự án trước — code giao diện với `figma-mcp-go`. Dự án lần này là codebase thật, cần:

1. Leader dùng skill superpowers (`brainstorming`, `writing-plans`, `systematic-debugging`) thay vì chỉ lập plan thủ công.
2. Thêm vai trò cho `librarian`: chủ động dùng skill `grill-me` (variant `chat.md`/`code.md`) để hỏi xoáy user về kiến trúc/thiết kế, rồi ghi vào Second Brain (`claude/wiki/`).

Khảo sát phát hiện thêm 2 vấn đề cần sửa trong lúc cập nhật:

- `librarian.md` đang tham chiếu schema cũ (`memory/memory_index.json`, `memory/wiki/index.md`, `memory/wiki/log.md`) — các file/thư mục này **không tồn tại** trong repo. Schema thật đang dùng là `claude/wiki/{architecture.md,decisions/,prd/,issues/}` với frontmatter `status`, đúng như mô tả trong `CLAUDE.md` gốc.
- `team.md` có lỗi chính tả (`librariann`) và không hề nhắc tới `librarian` trong quy trình làm việc thực tế, dù có liệt kê trong danh sách team.
- `reviewer.md` có `name: review` trong frontmatter nhưng mọi nơi khác (bao gồm `team.md`) đều gọi agent này là `reviewer`.

## Mục tiêu

- Leader lập kế hoạch cho feature/kiến trúc lớn bằng `brainstorming` → `writing-plans`; cho bugfix bằng `systematic-debugging`.
- Librarian sở hữu bước 1–3 của pipeline trong `CLAUDE.md` (Idea → Research → Decision Log): chủ động hỏi xoáy bằng `grill-me`, ghi Decision Log vào `claude/wiki/decisions/`, dừng lại trước khi viết PRD.
- Leader sở hữu bước 5–6 (`write-a-prd`, `prd-to-issues`) sau khi nhận Decision Log từ librarian.
- Coder có thêm `tdd` để implement theo red-green-refactor khi task có tiêu chí verify rõ ràng hoặc là bugfix.
- Reviewer có thêm `superpowers:verification-before-completion` làm gate trước khi kết luận pass, và sửa lỗi tên agent.
- `team.md` phản ánh đúng khi nào librarian được gọi trong vòng lặp leader↔coder↔reviewer.
- Sửa mọi tham chiếu schema cũ trong `librarian.md` sang schema `claude/wiki/` thật.

## Kiến trúc tổng thể — luồng end-to-end

```
User nêu ý tưởng / feature mới / thay đổi kiến trúc
        │
        ▼
Leader gọi librarian (operation GRILL)
        │  - đọc frontmatter PRD Active trong claude/wiki/prd/
        │  - explore code thật nếu PRD liên quan có thể đã lệch
        │  - chọn grill-me chat.md (câu trả lời nằm trong hội thoại)
        │    hoặc code.md (câu trả lời cần explore codebase)
        │  - hỏi xoáy từng câu, luôn kèm đề xuất
        ▼
Librarian ghi Decision Log → claude/wiki/decisions/<slug>-decision-log.md
        │  (status: Active) — DỪNG, không tự viết PRD
        ▼
Leader: brainstorming (nếu Decision Log chưa đủ rõ) → write-a-prd → prd-to-issues
        │  → claude/wiki/prd/<slug>.md, claude/wiki/issues/*.md
        ▼
Leader: writing-plans → brief chi tiết cho coder
        │
        ▼
┌─────────────────────────────────────────────┐
│  Vòng lặp chính (không đổi, qua SendMessage) │
│  Leader → Coder (tdd nếu cần) → Reviewer      │
│  (verification-before-completion trước pass)  │
│  Pass → báo leader → còn task? → lặp lại      │
│  Không pass → đẩy lại coder                   │
└─────────────────────────────────────────────┘
        │
        ▼ (nếu task ảnh hưởng kiến trúc/module đáng kể)
Leader gọi librarian (operation UPDATE) → sync claude/wiki/ phản ánh code thật
```

Nhánh bugfix nhỏ: `Leader (systematic-debugging) → Coder (tdd) → Reviewer`, bỏ qua librarian/brainstorming/writing-plans.

Task vụn vặt (fix typo, đổi text...): không qua librarian, không qua brainstorming — leader giao thẳng coder.

## 1. `leader.md` — thay đổi

Thêm vào "Skill được phép dùng":

| Skill | Trigger |
|---|---|
| `superpowers:brainstorming` | Feature mới / thay đổi kiến trúc đáng kể, chỉ khi Decision Log từ librarian (hoặc ý tưởng user nêu, nếu chưa qua librarian) chưa đủ rõ. Một khi đã trigger thì bắt buộc, không bỏ qua vì "thấy đơn giản". |
| `superpowers:writing-plans` | Sau khi brainstorming chốt design, viết plan chi tiết trước khi giao coder. |
| `superpowers:systematic-debugging` | Task là bugfix (không phải feature mới): lập kế hoạch điều tra root cause trước khi giao coder. Thay thế nhánh brainstorming/writing-plans cho loại task này. |
| `write-a-prd` | Sau khi nhận Decision Log từ librarian, soạn PRD đầy đủ → `claude/wiki/prd/<slug>.md`. |
| `prd-to-issues` | Sau `write-a-prd`, chia PRD thành issues → `claude/wiki/issues/`. |
| `improve-codebase-architecture` | Chỉ khi **user yêu cầu rõ ràng** một đợt rà soát/refactor kiến trúc — không tự chạy trong luồng plan feature/bugfix thông thường. Cùng nhóm gate với `schedule`/`loop`/`skill-creator` đã có sẵn. |

Giữ nguyên toàn bộ phần còn lại của `leader.md` (nguyên tắc, format kế hoạch, quy tắc truyền link Figma...) — không đụng vào những gì không liên quan.

## 2. `librarian.md` — viết lại

**Sửa schema (bắt buộc):** thay mọi tham chiếu `memory/memory_index.json`, `memory/wiki/index.md`, `memory/wiki/log.md` bằng `claude/wiki/architecture.md`, `claude/wiki/decisions/`, `claude/wiki/prd/`, `claude/wiki/issues/`. Orientation step mới: đọc `architecture.md` + frontmatter mọi PRD `status: Active` (không đọc toàn bộ nội dung).

**Operation mới — GRILL:**

```
1. Đọc frontmatter mọi PRD status: Active trong claude/wiki/prd/
2. Với PRD Active liên quan đến ý tưởng mới → explore code thật (module/file
   PRD đó mô tả) để kiểm tra PRD còn khớp thực tế không
3. Nếu phát hiện trùng/lệch → hỏi user ngay, không tự gán status: Superseded
   khi chưa được xác nhận
4. Chọn variant: chat.md (câu trả lời nằm trong hội thoại hiện tại) hoặc
   code.md (câu trả lời cần explore codebase thật)
5. Hỏi xoáy từng câu một, luôn kèm đề xuất, đến khi hết fork mở
6. Ghi Decision Log → claude/wiki/decisions/<slug>-decision-log.md
   (frontmatter: status: Active, date: <ngày tạo>)
7. Ghi log vào claude/wiki/log.md (tạo mới nếu chưa có)
8. DỪNG — không tự viết PRD (việc của leader ở write-a-prd)
```

**Operation UPDATE / LINT:** giữ tinh thần cũ (đọc code thật → cập nhật wiki, overwrite không append, State Drift là kẻ thù số 1) nhưng toàn bộ đường dẫn chuyển sang schema `claude/wiki/`. LINT kiểm tra `status` frontmatter thay vì kiểu "Last updated" cũ.

**Skill được phép dùng — thêm:** `grill-me` (2 variant). Giữ nguyên cấm `review`/`simplify`/`security-review`.

## 3. `coder.md` — thay đổi

Thêm vào "Skill được phép dùng": `tdd` — dùng khi brief từ leader có tiêu chí verify rõ ràng (từ `writing-plans`) hoặc task là bugfix (từ `systematic-debugging`): viết test tái hiện/xác nhận trước, code sau (red-green-refactor).

Giữ nguyên 100% phần quy tắc Figma/UI hiện có — vẫn là nhánh hợp lệ song song, không thay thế.

## 4. `reviewer.md` — thay đổi

- **Sửa lỗi:** frontmatter `name: review` → `name: reviewer` (khớp cách team.md và các agent khác gọi nó).
- **Thêm skill:** `superpowers:verification-before-completion` — chạy trước khi kết luận "LGTM"/pass, đảm bảo nhận định dựa trên evidence (lint/test/build thật chạy được) chứ không chỉ đọc code bằng mắt.

Không đổi checklist/format báo cáo hiện có.

## 5. `team.md` — thay đổi

- Sửa lỗi chính tả `librariann` → `librarian`.
- Giữ nguyên vòng lặp chính (leader → coder → reviewer → pass/fail, qua SendMessage trong tmux, không spawn subagent mới).
- Thêm mục "Khi nào gọi librarian":
  - Trước khi lập plan cho feature mới/thay đổi kiến trúc đáng kể → leader gọi librarian (GRILL) → chờ Decision Log trước khi brainstorming/write-a-prd/writing-plans.
  - Sau khi reviewer pass một task ảnh hưởng kiến trúc/module đáng kể → leader gọi librarian (UPDATE) sync wiki.
  - Task nhỏ (fix typo, đổi text...) → không cần gọi librarian.
  - Leader không chắc task có "đáng kể" hay không → hỏi user, không tự quyết.

## Rủi ro / Đánh đổi

- **Thêm độ trễ cho feature lớn**: luồng đầy đủ (librarian GRILL → leader brainstorming → write-a-prd → prd-to-issues → writing-plans) dài hơn đáng kể so với giao thẳng coder như trước. Chấp nhận được vì đây là chủ đích của user (đổi từ code UI nhanh sang codebase cần đúng kiến trúc).
- **Ai quyết "đáng kể" hay không** (để gọi librarian UPDATE sau mỗi task) là phán đoán chủ quan của leader — nếu sai có thể bỏ sót sync wiki. Giảm thiểu bằng quy tắc "không chắc → hỏi user".
- **`librarian.md` viết lại gần như toàn bộ** — rủi ro mất tinh thần cũ ("chỉ ghi sự thật hiện tại", "overwrite không append", State Drift warning) nếu không cẩn thận khi port sang schema mới. Cần giữ nguyên các nguyên tắc này, chỉ đổi đường dẫn/schema.

## Ngoài phạm vi

- Không đổi cơ chế `TeamsCreate`/SendMessage/tmux — đó là hạ tầng có sẵn, không phải nội dung brainstorm này.
- Không thêm `superpowers:requesting-code-review`/`receiving-code-review` — trùng chức năng với vòng lặp leader↔coder↔reviewer đã có sẵn qua team.md.
- Không đổi model gán cho từng agent (leader=fable 5, coder=sonnet 5, reviewer=sonnet 5, librarian=sonnet 4.6).
