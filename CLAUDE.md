# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Bash: Kiểm tra working directory trước khi `cd`

**Đừng `cd` mù. Biết mình đang ở đâu trước đã.**

Trước khi chạy `cd <path>`:

- Chạy `pwd` (hoặc kiểm tra context working directory đã có sẵn) để xác định vị trí hiện tại.
- Nếu đã ở đúng thư mục cần đến → KHÔNG `cd`. Chạy lệnh trực tiếp.
- Nếu cần dùng đường dẫn → ưu tiên đường dẫn tuyệt đối hoặc tương đối từ vị trí hiện tại thay vì `cd` rồi chạy.
- Không nối `cd <current-dir> && <command>` — vô nghĩa và gây prompt permission thừa.

Quy tắc áp dụng cho mọi agent (leader, coder, reviewer) và mọi lệnh Bash. `cd` chỉ chính đáng khi:

- Thật sự cần đổi sang thư mục khác để chạy lệnh phụ thuộc cwd (build script, package manager trong subpackage).
- User yêu cầu rõ ràng.

Sai: `cd /Users/bonn/Desktop/claude_demo_part2/claude_book && ls` (khi đã ở đó)
Đúng: `ls` (chạy thẳng)

## 6. Ngôn ngữ đầu ra

**Luôn trả lời user bằng tiếng Việt.**

- Mọi output hướng tới user (giải thích, báo cáo, tóm tắt, câu hỏi clarify) đều viết bằng tiếng Việt.
- Áp dụng cho toàn bộ agent: phiên chính, leader, coder, reviewer, và teammate trong Agent Teams.
- Giữ nguyên tiếng Anh cho: tên file, tên biến, code, lệnh shell, error message gốc, thuật ngữ kỹ thuật không có bản dịch chuẩn (ví dụ: "merge", "rebase", "lint", "typecheck").
- Không dịch comment/code có sẵn trong file sang tiếng Việt trừ khi user yêu cầu.

## 7. Second Brain — Wiki Schema

**Đọc bộ não thứ 2 trước khi bắt đầu task quan trọng.**

### Vai trò của bạn trong repo này

Trước khi làm bất kỳ task nào: đọc mục "Bản đồ tra cứu" bên dưới để biết nên mở file nào. KHÔNG đọc toàn bộ `wiki/` hay toàn bộ codebase cùng lúc — chỉ lấy đúng phần cần, theo tinh thần layered context.

### Bản đồ tra cứu (Layered Context)

- Kiến trúc tổng thể repo: `claude/wiki/architecture.md`
- Quyết định/PRD đang còn hiệu lực: xem query Dataview bên dưới (mở trong Obsidian, vault = `claude/wiki/`) hoặc `grep -l "status: Active" claude/wiki/prd/*.md` (khi bạn tự tra bằng Read/Grep)
- Đang trong giai đoạn khám phá khó (research phase, chưa rõ giải pháp): đọc `claude/research.md` trước; nếu chưa có, tạo mới để cache phát hiện thay vì lặp lại việc khám phá ở session sau

```dataview
TABLE status, date
FROM "prd"
WHERE status = "Active"
SORT date DESC
```

### Quy tắc bắt buộc

- Không tự ý mở/query NotebookLM. NotebookLM là công cụ của người dùng để họ tự tổng hợp lại các PRD — không phải nguồn context cho bạn. Bạn luôn đọc trực tiếp file `.md` local qua Read/Grep.
- Không đọc file có `status: Superseded` hoặc `status: Archived` trừ khi người dùng yêu cầu tra lịch sử quyết định cũ.
- Khi có yêu cầu tính năng mới / thay đổi kiến trúc đáng kể, chạy đúng pipeline bên dưới theo thứ tự — không nhảy bước.

### Pipeline: tính năng mới / thay đổi lớn

Thao tác hàng ngày: Idea → Research [optional] → Decision Log → Prototype [optional] → PRD → Kanban → Implementation → QA/Code Review → Sync vào wiki → NotebookLM (người dùng tự làm).

**Bước 1 — Idea (grill-me)**

Dùng skill tại: `claude/skills/grill-me/chat.md`

Trước khi hỏi câu đầu tiên:

1. Đọc frontmatter + dòng tóm tắt của mọi PRD `status: Active` trong `claude/wiki/prd/` (không đọc toàn bộ nội dung).
2. Với PRD Active nào có vẻ liên quan đến ý tưởng mới, explore trực tiếp codebase thật (module/file mà PRD đó mô tả) để kiểm tra PRD còn khớp với code hiện tại không — PRD là ý định, code mới là sự thật. Nếu PRD cũ đã lệch so với code thực tế, đó là tín hiệu xung đột/lỗi thời cần nêu ra, kể cả khi chưa viết PRD mới.
3. Nếu phát hiện trùng/xung đột (qua PRD text hoặc qua thực tế code), hỏi ngay: "PRD X đang Active có vẻ liên quan/đã lệch so với code hiện tại — bạn muốn PRD mới supersede nó, hay đây là 2 việc độc lập?"

Chỉ sau khi người dùng xác nhận, Claude mới tự sửa frontmatter PRD cũ thành `Superseded` — không tự gán nhãn khi chưa hỏi. Hỏi xoáy tiếp phần còn lại của ý tưởng đến khi hết fork mở, không hỏi lại điều đã có trong session.

**Bước 2 — Research [optional]**

Chỉ khi Bước 1 gặp giai đoạn khám phá khó (chưa rõ giải pháp kỹ thuật, cần đọc tài liệu ngoài/thử nghiệm). Cache phát hiện vào `claude/research.md` trước khi chốt Decision Log, tránh lặp lại việc khám phá ở session sau. Bỏ qua nếu ý tưởng đã đủ rõ.

**Bước 3 — Lưu Decision Log**

Ghi output Bước 1 (+ Bước 2 nếu có) vào `claude/wiki/decisions/<slug>-decision-log.md`, frontmatter:

```
status: Active
date: <ngày tạo>
```

**Bước 4 — Prototype [optional]**

Chỉ khi cần thử nhanh ý tưởng bằng code để lấy phản hồi sớm trước khi cam kết viết PRD đầy đủ. Code nháp, không phải production code, không cần test đầy đủ — nhưng giữ lại làm tài nguyên tái sử dụng cho Implementation (Bước 7). Bỏ qua nếu Decision Log đã đủ rõ để viết PRD thẳng.

**Bước 5 — Soạn PRD đầy đủ (write-a-prd)**

Dùng skill tại: `claude/skills/write-a-prd/SKILL.md`

Input: Decision Log (+ Prototype nếu có). Output: PRD lưu vào `claude/wiki/prd/<slug>.md`, frontmatter:

```
status: Active
date: <ngày tạo>
supersedes: <slug PRD cũ, nếu có>
```

Nếu PRD này thay thế PRD cũ → đổi status của PRD cũ thành `Superseded`.

**Bước 6 — Kanban (prd-to-issues)**

Dùng skill tại: `claude/skills/prd-to-issues/SKILL.md`

Input: Decision Log + PRD ở Bước 5. Output: các thẻ issue trong `claude/wiki/issues/`, mỗi issue có frontmatter:

```
status: todo
```

Cập nhật `status: in-progress` / `status: done` khi tiến triển — đây là cơ chế Kanban tracking. `claude/wiki/issues/` nằm trong vault Obsidian nên board Kanban xem được qua Dataview (query mẫu ở `claude/wiki/architecture.md`).

**Bước 7 — Implementation**

Chạy coding agent theo vòng lặp để thực thi các thẻ Kanban còn `status: todo`. Cơ chế cụ thể (vd skill `superpowers:subagent-driven-development`, `superpowers:dispatching-parallel-agents`, hay `/loop`) — **chưa chốt**, thống nhất với người dùng khi thực sự tới giai đoạn này cho từng PRD cụ thể.

**Bước 8 — QA / Code Review**

Sau khi thẻ Kanban chuyển `status: done`, tạo kế hoạch QA để người dùng trực tiếp kiểm thử thủ công, kết hợp code review (skill `code-review` / `security-review` có sẵn trong repo). Format/vị trí lưu kế hoạch QA cụ thể — **chưa chốt**.

**Bước 9 — Sync vào wiki**

Không cần thao tác thêm — PRD ở Bước 5 đã nằm trong `claude/wiki/prd/`, Dataview query đầu file này tự động thấy nó vì `status: Active`.

**Bước 10 — NotebookLM (người dùng tự làm, bạn chỉ nhắc)**

Kết thúc pipeline bằng câu nhắc, không tự động thực hiện:

> "PRD mới đã sẵn sàng tại `claude/wiki/prd/<slug>.md`. Bạn tự upload vào NotebookLM notebook của repo này nếu muốn tổng hợp/review lại sau."

### Cấu trúc thư mục chuẩn cho repo này

```
skills/                      ← repo root
├── CLAUDE.md                ← chính là file này
└── claude/
    ├── research.md          ← cache phát hiện từ các giai đoạn khám phá khó
    └── wiki/                ← vault Obsidian, root = claude/wiki/.obsidian
        ├── architecture.md
        ├── log.md           ← nhật ký thao tác của librarian: ingest/update/lint
        ├── decisions/
        │   └── <slug>-decision-log.md
        ├── prd/
        │   └── <slug>.md    ← frontmatter status: Active/Superseded/Archived
        └── issues/          ← Kanban: <slug-NNN>-title.md, frontmatter status: todo/in-progress/done
```

Mỗi repo có `wiki/` riêng bên trong chính nó + 1 NotebookLM notebook riêng — không dùng chung wiki trung tâm giữa các repo.

### Ghi nhớ triết lý (để không lặp lại lỗi cũ)

- Wiki cũ từng phình quá 300k token vì nội dung khó kiểm chứng, cấu trúc xung đột → mọi trang trong `claude/wiki/decisions/` và `claude/wiki/prd/` PHẢI có frontmatter `status`, không được để mồ côi.
- Không ai tự tay gắn nhãn status, và Claude không tự ý gắn nhãn một mình. PRD chỉ đáng tin khi được validate qua codebase thật (không phải vì được ghi trong markdown) — vì vậy grill-me luôn explore code trước khi hỏi xoáy, và chỉ đổi `status: Superseded` sau khi người dùng xác nhận.
- Đừng nạp cả `wiki/` vào context một lần — chỉ đọc đúng file theo Bản đồ tra cứu hoặc Dataview query ở trên.
- NotebookLM không phải nguồn context cho Claude — chỉ để người dùng tự tổng hợp; đừng thêm bước gọi NotebookLM qua Claude-in-Chrome vào pipeline này.
