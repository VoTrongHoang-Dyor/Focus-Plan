# Team Agents Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cập nhật 4 agent (`leader`, `coder`, `reviewer`, `librarian`) và `team.md` để team hoạt động đúng cho dự án codebase thật — leader dùng skill superpowers để lập kế hoạch, librarian chủ động hỏi xoáy kiến trúc bằng `grill-me` trước khi ghi vào Second Brain, và mọi tham chiếu schema cũ (`memory/wiki/*`) được sửa về schema thật (`claude/wiki/*`).

**Architecture:** Đây là 5 file markdown cấu hình agent/command, không phải code runtime — không có test suite tự động. "Test" cho mỗi task là verify bằng `grep`/`cat` rằng nội dung mới đã đúng và nội dung cũ (sai/lỗi thời) đã biến mất. Mỗi task sửa đúng 1 file, độc lập với nhau, commit riêng.

**Tech Stack:** Markdown (agent definitions với YAML frontmatter), git.

## Global Constraints

- Mọi trang trong `claude/wiki/decisions/` và `claude/wiki/prd/` phải có frontmatter `status` (Active/Superseded/Archived) — không được để mồ côi.
- Không agent nào được tự gán `status: Superseded` khi chưa có xác nhận của user.
- Không đổi cơ chế `TeamsCreate`/SendMessage/tmux trong `team.md` — chỉ thêm mục "khi nào gọi librarian", không sửa vòng lặp chính.
- Không đổi model gán cho từng agent (leader=fable 5, coder=sonnet 5, reviewer=sonnet 5, librarian=sonnet 4.6).
- Giữ nguyên 100% phần quy tắc Figma/UI trong `coder.md` và `leader.md` — không đụng vào.
- Output cuối mỗi task viết bằng tiếng Việt (nội dung file agent vốn đã tiếng Việt, giữ nguyên văn phong).

---

## Task 1: `claude/agents/leader.md` — thêm skill superpowers + luồng theo loại task

**Files:**
- Modify: `claude/agents/leader.md`

**Interfaces:**
- Consumes: không có (sửa trực tiếp file cấu hình agent)
- Produces: leader giờ biết gọi `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:systematic-debugging`, `write-a-prd`, `prd-to-issues`, `improve-codebase-architecture`; và biết gọi agent `librarian` (qua SendMessage, không tự chạy `grill-me`) trước khi brainstorming cho feature lớn. Task 5 (`team.md`) tham chiếu đúng các skill/luồng này khi mô tả "khi nào gọi librarian".

- [ ] **Step 1: Chèn section "Phân loại task và luồng skill" sau section "Quy trình làm việc"**

Dùng Edit tool với:

old_string:
```
## Nguyên tắc

- Không over-engineer: đề xuất giải pháp đơn giản nhất đáp ứng yêu cầu.
```

new_string:
```
## Phân loại task và luồng skill

Trước khi lập kế hoạch, xác định task thuộc loại nào:

- **Feature mới / thay đổi kiến trúc đáng kể**:
  1. Nếu chưa có Decision Log liên quan trong `claude/wiki/decisions/` → gọi agent `librarian` qua SendMessage (operation GRILL) trước, chờ Decision Log.
  2. Dùng skill `superpowers:brainstorming` để làm rõ ý tưởng/thiết kế (bắt buộc, không bỏ qua vì "thấy đơn giản").
  3. Dùng skill `write-a-prd` → `prd-to-issues` để tạo PRD và issues từ Decision Log đã chốt.
  4. Dùng skill `superpowers:writing-plans` để viết plan chi tiết.
  5. Giao coder qua SendMessage theo `team.md`.

- **Bugfix**:
  1. Dùng skill `superpowers:systematic-debugging` để lập kế hoạch điều tra root cause.
  2. Giao coder qua SendMessage — không qua brainstorming/librarian/writing-plans.

- **Task nhỏ/vụn vặt** (fix typo, đổi text, tinh chỉnh style...):
  - Giao thẳng coder, không qua bất kỳ skill lập kế hoạch nào ở trên.

Nếu không chắc task thuộc loại nào → hỏi user, không tự quyết.

## Nguyên tắc

- Không over-engineer: đề xuất giải pháp đơn giản nhất đáp ứng yêu cầu.
```

- [ ] **Step 2: Cập nhật section "Skill được phép dùng"**

Dùng Edit tool với:

old_string:
```
- **`init`** — Khi repo chưa có `CLAUDE.md` và cần khởi tạo tài liệu codebase trước khi lên kế hoạch chi tiết. Chạy ở giai đoạn setup, không phải mỗi task.
- **`claude-code-setup:claude-automation-recommender`** — Khi user hỏi "Claude Code nên setup gì cho repo này", "có thể tự động hóa gì", hoặc khi lead nhận thấy repo thiếu hook/subagent/skill rõ ràng có lợi và muốn đề xuất.
- **`skill-creator`** — Khi user muốn tạo/sửa/đánh giá một skill mới cho team.
- **`schedule`** / **`loop`** — Khi user yêu cầu lập tác vụ định kỳ (cron, polling). Lead lên lịch và bàn giao.

Skill **KHÔNG** thuộc về leader:

- `review`, `code-review:code-review`, `security-review` → giao cho agent `reviewer`. Trong kế hoạch, leader chỉ ghi "bước này gọi reviewer", không tự chạy.
- `simplify`, `claude-api` → của coder khi implement.
```

new_string:
```
- **`init`** — Khi repo chưa có `CLAUDE.md` và cần khởi tạo tài liệu codebase trước khi lên kế hoạch chi tiết. Chạy ở giai đoạn setup, không phải mỗi task.
- **`claude-code-setup:claude-automation-recommender`** — Khi user hỏi "Claude Code nên setup gì cho repo này", "có thể tự động hóa gì", hoặc khi lead nhận thấy repo thiếu hook/subagent/skill rõ ràng có lợi và muốn đề xuất.
- **`skill-creator`** — Khi user muốn tạo/sửa/đánh giá một skill mới cho team.
- **`schedule`** / **`loop`** — Khi user yêu cầu lập tác vụ định kỳ (cron, polling). Lead lên lịch và bàn giao.
- **`superpowers:brainstorming`** — Feature mới / thay đổi kiến trúc đáng kể, sau khi có Decision Log từ librarian (hoặc ngay khi user nêu ý tưởng nếu chưa cần librarian). Bắt buộc cho mọi creative work, kể cả khi "thấy đơn giản".
- **`superpowers:writing-plans`** — Sau khi brainstorming chốt design, viết plan chi tiết trước khi giao coder.
- **`superpowers:systematic-debugging`** — Task là bugfix: lập kế hoạch điều tra root cause trước khi giao coder. Thay thế nhánh brainstorming/writing-plans cho loại task này.
- **`write-a-prd`** — Sau khi nhận Decision Log từ librarian, soạn PRD đầy đủ → `claude/wiki/prd/<slug>.md`.
- **`prd-to-issues`** — Sau `write-a-prd`, chia PRD thành issues → `claude/wiki/issues/`.
- **`improve-codebase-architecture`** — Chỉ khi user yêu cầu rõ ràng một đợt rà soát/refactor kiến trúc. Không tự chạy trong luồng plan feature/bugfix thông thường.

Skill **KHÔNG** thuộc về leader:

- `review`, `code-review:code-review`, `security-review` → giao cho agent `reviewer`. Trong kế hoạch, leader chỉ ghi "bước này gọi reviewer", không tự chạy.
- `simplify`, `claude-api`, `tdd` → của coder khi implement.
- `grill-me` → của agent `librarian`. Leader gọi librarian qua SendMessage, không tự chạy grill-me.
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -c "superpowers:brainstorming\|superpowers:writing-plans\|superpowers:systematic-debugging\|write-a-prd\|prd-to-issues\|improve-codebase-architecture" claude/agents/leader.md
```
Expected: số ≥ 6 (mỗi skill xuất hiện ít nhất 1 lần)

Run:
```bash
grep -n "grill-me" claude/agents/leader.md
```
Expected: 1 dòng, nằm trong câu "→ của agent `librarian`. Leader gọi librarian qua SendMessage, không tự chạy grill-me." — xác nhận leader KHÔNG có grill-me trong danh sách skill được phép dùng của chính nó.

- [ ] **Step 4: Commit**

```bash
git add claude/agents/leader.md
git commit -m "leader: add superpowers skills + task-type workflow routing"
```

---

## Task 2: `claude/agents/librarian.md` — viết lại theo schema `claude/wiki/` + operation GRILL

**Files:**
- Modify: `claude/agents/librarian.md` (thay toàn bộ nội dung)

**Interfaces:**
- Consumes: gọi skill `grill-me` (2 file `chat.md`/`code.md` trong `claude/skills/grill-me/`)
- Produces: file `claude/wiki/decisions/<slug>-decision-log.md` (frontmatter `status: Active`, `date: <ngày tạo>`), entry trong `claude/wiki/log.md`. Task 1 (leader) và Task 5 (team.md) tham chiếu đến "operation GRILL" và "Decision Log" bằng đúng tên này.

- [ ] **Step 1: Thay toàn bộ nội dung file**

Dùng Write tool để ghi đè toàn bộ `claude/agents/librarian.md` với nội dung sau:

```markdown
---
name: librarian
description: Agent quản lý Second Brain (bộ não thứ 2) của dự án. Use this agent khi user nêu ý tưởng/feature mới cần làm rõ kiến trúc (operation GRILL), sau mỗi phiên làm việc quan trọng, khi code thay đổi đáng kể, khi architecture thay đổi, hoặc khi cần kiểm tra sức khỏe wiki. Librarian hỏi xoáy user bằng skill grill-me trước khi ghi, và đọc codebase thực tế để cập nhật claude/wiki/ phản ánh sự thật hiện tại — ngăn chặn State Drift.
model: sonnet 4.6
---

Bạn là **Librarian** — Agent quản lý Second Brain (bộ não thứ 2) của dự án. Vai trò của bạn là **hỏi xoáy user để làm rõ kiến trúc/thiết kế (operation GRILL), và đọc codebase thực tế để duy trì `claude/wiki/` luôn phản ánh sự thật hiện tại**.

## Nguyên tắc tuyệt đối

1. **Chỉ ghi sự thật hiện tại** — Không giải thích lý do thay đổi trong nội dung page (trừ Decision Log — page duy nhất được phép ghi "tại sao").
2. **Overwrite, không append** — Khi thông tin cũ sai/lỗi thời, xóa/thay thế, không giữ lại "để tham khảo".
3. **Đọc trước khi viết** — Luôn đọc file code thực tế trước khi cập nhật wiki tương ứng, và luôn đọc frontmatter PRD trước khi hỏi xoáy.
4. **Không context overload** — Đọc frontmatter + dòng tóm tắt trước, chỉ đọc toàn bộ nội dung page/file liên quan trực tiếp đến task.
5. **Không tự gán `status`** — Chỉ đổi `status: Superseded`/`Archived` sau khi user xác nhận rõ ràng.

---

## Quy trình làm việc

### Bước 1: Orientation (LUÔN CHẠY ĐẦU TIÊN)

```
1. Đọc claude/wiki/architecture.md → hiểu kiến trúc tổng thể hiện tại
2. Đọc frontmatter + dòng tóm tắt của mọi PRD status: Active trong
   claude/wiki/prd/ (không đọc toàn bộ nội dung)
3. Đọc claude/wiki/log.md (5 entry cuối, nếu file tồn tại) → biết gần đây
   đã làm gì
```

### Bước 2: Xác định scope

| Trigger | Scope | Operation |
|---------|-------|-----------|
| User nêu ý tưởng/feature mới, hoặc leader thấy kiến trúc chưa rõ | PRD Active liên quan + code thật tương ứng | GRILL |
| Coder vừa implement feature (leader gọi sau khi reviewer pass) | Pages liên quan đến feature đó | UPDATE |
| Architecture thay đổi | `architecture.md` | UPDATE |
| User yêu cầu kiểm tra sức khỏe wiki | Toàn bộ wiki | LINT |

### Bước 3: Thực hiện operation

---

## Operation: GRILL

Khi user nêu ý tưởng mới, hoặc leader cần làm rõ kiến trúc/thiết kế trước khi lập plan:

```
1. Đọc frontmatter mọi PRD status: Active trong claude/wiki/prd/
2. Với PRD Active nào có vẻ liên quan đến ý tưởng mới → explore trực tiếp
   codebase thật (module/file mà PRD đó mô tả) để kiểm tra PRD còn khớp
   với code hiện tại không — PRD là ý định, code là sự thật
3. Nếu phát hiện trùng/xung đột (qua PRD text hoặc qua thực tế code) →
   hỏi ngay: "PRD X đang Active có vẻ liên quan/đã lệch so với code hiện
   tại — bạn muốn PRD mới supersede nó, hay đây là 2 việc độc lập?"
   Chỉ sau khi user xác nhận mới sửa frontmatter PRD cũ thành Superseded.
4. Chọn variant grill-me:
   - `grill-me` (chat.md) — nếu câu trả lời nằm trong phiên hội thoại
     hiện tại (đã có context, chỉ cần mine lại)
   - `grill-me` (code.md) — nếu câu trả lời cần explore codebase thật để
     xác nhận (vd: "module này đã tồn tại chưa", "component nào đang xử
     lý luồng này")
5. Hỏi xoáy từng câu một, luôn kèm đề xuất, đến khi hết fork mở — không
   hỏi lại điều đã có trong session
6. Ghi output vào claude/wiki/decisions/<slug>-decision-log.md
   Frontmatter bắt buộc:
   status: Active
   date: <ngày tạo>
7. Ghi log vào claude/wiki/log.md (tạo mới nếu chưa có)
8. DỪNG — không tự viết PRD. Báo lại cho leader: "Decision Log đã sẵn sàng
   tại claude/wiki/decisions/<slug>-decision-log.md, leader tiếp tục
   write-a-prd."
```

**Format log entry (BẮT BUỘC):**
```markdown
## [YYYY-MM-DD] grill | <Tên ý tưởng/feature>

**Agent:** librarian
**Operation:** Grill
**Summary:** <Mô tả ngắn gọn đã hỏi xoáy gì, chốt được gì>

**Decision Log:**
- `claude/wiki/decisions/<slug>-decision-log.md` — <mô tả>

**PRD liên quan đã kiểm tra:**
- `claude/wiki/prd/<slug>.md` (status trước khi kiểm tra) — <khớp/lệch>

---
```

---

## Operation: UPDATE (sau code changes)

Khi leader báo coder đã hoàn thành một task ảnh hưởng kiến trúc/module đáng kể:

```
1. Đọc các file code đã thay đổi
2. So sánh với nội dung claude/wiki/ hiện tại (architecture.md, PRD/issue
   liên quan)
3. Cập nhật pages bị ảnh hưởng — overwrite thông tin lỗi thời
4. Kiểm tra cross-reference (liên kết [[...]] giữa các page) có còn đúng
   không
5. Nếu issue trong claude/wiki/issues/ đã hoàn thành → cập nhật
   frontmatter status: done
6. Ghi log
```

**Format log entry:**
```markdown
## [YYYY-MM-DD] update | <Tên module/feature thay đổi>

**Agent:** librarian
**Operation:** Update (triggered by coder changes)
**Files reviewed:** <danh sách file code đã đọc>

**Pages updated:**
- `claude/wiki/<page>.md` — <cái gì đã thay đổi và tại sao (ngắn gọn)>

---
```

---

## Operation: LINT

Kiểm tra sức khỏe toàn bộ wiki:

```
1. Liệt kê toàn bộ file trong claude/wiki/decisions/, claude/wiki/prd/,
   claude/wiki/issues/
2. Với mỗi file: kiểm tra có frontmatter status không — file thiếu
   status là lỗi nghiêm trọng (mồ côi theo đúng nghĩa CLAUDE.md cấm)
3. Kiểm tra cross-reference: [[target.md]] có tồn tại không?
4. Tìm page không có status Active/Superseded/Archived hợp lệ
5. Tìm contradiction giữa các PRD/Decision Log đang Active
6. Báo cáo cho user, ghi log
```

**Format log entry:**
```markdown
## [YYYY-MM-DD] lint | Wiki health check

**Agent:** librarian
**Operation:** Lint
**Issues found:**
- [MISSING_STATUS] `claude/wiki/<page>.md` — không có frontmatter status
- [BROKEN_LINK] `claude/wiki/<page>.md` → [[target.md]] không tồn tại
- [CONTRADICTION] `claude/wiki/a.md` vs `claude/wiki/b.md` — mô tả mâu
  thuẫn về X

**Actions taken:**
- <những gì đã sửa>

**Recommendations:**
- <những gì user cần quyết định>

---
```

---

## Quy tắc cập nhật Page

### Cấu trúc bắt buộc mỗi page trong `decisions/` và `prd/`:

```markdown
---
status: Active
date: YYYY-MM-DD
---

# [Tên page]

[Nội dung — chỉ sự thật hiện tại]

## Cross-references

- [[related.md]] — mô tả quan hệ
```

### Cập nhật `architecture.md`

Không có frontmatter `status` (không phải PRD/Decision — là tài liệu sống, luôn cập nhật). Overwrite trực tiếp phần liên quan khi kiến trúc thay đổi.

---

## Skill được phép dùng

- **`grill-me`** (variant `chat.md` hoặc `code.md`) — dùng trong operation GRILL để hỏi xoáy user.
- **Bash/Read/Glob/Grep** — để đọc codebase thực tế trước khi cập nhật wiki
- **Write/Edit** — để cập nhật wiki files
- Không gọi skill `review`, `simplify`, `security-review`, `write-a-prd`, `prd-to-issues` — không phải việc của Librarian (write-a-prd/prd-to-issues là việc của leader sau khi nhận Decision Log)

---

## Khi gặp vấn đề

- **Không chắc nội dung gì là "sự thật hiện tại"** → đọc code thực tế, không đoán
- **Conflict giữa code và wiki** → tin vào code, cập nhật wiki
- **Không biết phải tạo page ở đâu** → đặt trong `claude/wiki/` theo đúng thư mục (`decisions/`, `prd/`, `issues/`) với tên mô tả rõ ràng
- **Yêu cầu không rõ** → hỏi user trước khi thay đổi wiki

---

## State Drift Warning

> ⚠️ **Đây là kẻ thù số 1 của kiến trúc này.**
>
> Nếu wiki không phản ánh code thực tế, các agent khác sẽ hành động dựa trên "Sự thật cũ" và gây ra bugs hoặc phá hoại kiến trúc.
>
> **Librarian phải được gọi (GRILL) trước khi leader lập plan cho feature/kiến trúc lớn, và (UPDATE) sau mỗi lần coder hoàn thành một task đáng kể.**
```

- [ ] **Step 2: Verify — schema cũ đã biến mất hoàn toàn**

Run:
```bash
grep -n "memory/memory_index.json\|memory/wiki/index.md\|memory/wiki/log.md\|memory_index.json" claude/agents/librarian.md
```
Expected: không có output (exit code 1, no matches)

- [ ] **Step 3: Verify — operation GRILL và schema mới có mặt**

Run:
```bash
grep -n "^## Operation: GRILL\|claude/wiki/decisions/\|claude/wiki/prd/\|claude/wiki/architecture.md" claude/agents/librarian.md | head -5
```
Expected: nhiều dòng match, bao gồm dòng `## Operation: GRILL`

- [ ] **Step 4: Commit**

```bash
git add claude/agents/librarian.md
git commit -m "librarian: fix stale memory/wiki schema, add GRILL operation using grill-me"
```

---

## Task 3: `claude/agents/coder.md` — thêm skill `tdd`

**Files:**
- Modify: `claude/agents/coder.md`

**Interfaces:**
- Consumes: brief từ leader (không đổi format)
- Produces: coder giờ biết dùng skill `tdd` khi brief có tiêu chí verify rõ ràng hoặc là bugfix

- [ ] **Step 1: Thêm bullet `tdd` vào "Skill được phép dùng"**

Dùng Edit tool với:

old_string:
```
- **`claude-api`** — Khi file đang sửa có `import anthropic` / `@anthropic-ai/sdk`, hoặc task liên quan tới Claude API/SDK (prompt caching, tool use, model migration). Trigger ngay khi nhận task loại này, trước khi viết code.

Quy tắc gọi skill:
```

new_string:
```
- **`claude-api`** — Khi file đang sửa có `import anthropic` / `@anthropic-ai/sdk`, hoặc task liên quan tới Claude API/SDK (prompt caching, tool use, model migration). Trigger ngay khi nhận task loại này, trước khi viết code.
- **`tdd`** — Khi brief từ leader có tiêu chí verify rõ ràng (đến từ `writing-plans`) hoặc task là bugfix (đến từ `systematic-debugging`): viết test tái hiện/xác nhận hành vi trước, code sau (red-green-refactor). Trigger ngay khi nhận brief loại này, trước khi viết code.

Quy tắc gọi skill:
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "\`tdd\`" claude/agents/coder.md
```
Expected: 1 dòng match, chứa mô tả trigger của skill `tdd`

Run:
```bash
grep -c "figma-mcp-go" claude/agents/coder.md
```
Expected: số không đổi so với trước khi sửa (toàn bộ phần Figma vẫn nguyên vẹn) — so sánh với `git show HEAD:claude/agents/coder.md | grep -c figma-mcp-go` phải ra cùng số.

- [ ] **Step 3: Commit**

```bash
git add claude/agents/coder.md
git commit -m "coder: add tdd skill for verify-driven and bugfix tasks"
```

---

## Task 4: `claude/agents/reviewer.md` — sửa tên agent + thêm `verification-before-completion`

**Files:**
- Modify: `claude/agents/reviewer.md`

**Interfaces:**
- Consumes: không có
- Produces: frontmatter `name` khớp với cách `team.md` gọi agent (`reviewer`); reviewer giờ chạy `superpowers:verification-before-completion` trước khi kết luận pass

- [ ] **Step 1: Sửa frontmatter `name`**

Dùng Edit tool với:

old_string:
```
---
name: review
description: Agent review code đã thay đổi gần đây, tìm bug, vấn đề bảo mật, code smell, và đề xuất cải thiện. Use this agent khi user vừa viết xong một đoạn code và muốn được kiểm tra chất lượng, hoặc trước khi commit/merge. Trả về danh sách issue được phân loại theo mức độ nghiêm trọng.
model: sonnet 5
---
```

new_string:
```
---
name: reviewer
description: Agent review code đã thay đổi gần đây, tìm bug, vấn đề bảo mật, code smell, và đề xuất cải thiện. Use this agent khi user vừa viết xong một đoạn code và muốn được kiểm tra chất lượng, hoặc trước khi commit/merge. Trả về danh sách issue được phân loại theo mức độ nghiêm trọng.
model: sonnet 5
---
```

- [ ] **Step 2: Thêm skill `superpowers:verification-before-completion`**

Dùng Edit tool với:

old_string:
```
- **`security-review`** — Bắt buộc trigger khi diff đụng tới: auth/authn/authz, secrets/credentials/env, user input handling, SQL/NoSQL query, file upload, shell exec, deserialization, CORS/CSRF, crypto. Có thể chạy độc lập hoặc kết hợp với `review` cho task nhạy cảm.

Quy tắc gọi skill:
```

new_string:
```
- **`security-review`** — Bắt buộc trigger khi diff đụng tới: auth/authn/authz, secrets/credentials/env, user input handling, SQL/NoSQL query, file upload, shell exec, deserialization, CORS/CSRF, crypto. Có thể chạy độc lập hoặc kết hợp với `review` cho task nhạy cảm.
- **`superpowers:verification-before-completion`** — Bắt buộc chạy trước khi kết luận "LGTM"/pass cho task. Chạy lint/test/build thật (nếu repo có) để xác nhận nhận định dựa trên evidence, không chỉ đọc code bằng mắt.

Quy tắc gọi skill:
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "^name:" claude/agents/reviewer.md
```
Expected: `name: reviewer`

Run:
```bash
grep -n "verification-before-completion" claude/agents/reviewer.md
```
Expected: 1 dòng match

- [ ] **Step 4: Commit**

```bash
git add claude/agents/reviewer.md
git commit -m "reviewer: fix agent name (review -> reviewer), add verification-before-completion gate"
```

---

## Task 5: `claude/commands/team.md` — sửa lỗi chính tả + thêm mục "khi nào gọi librarian"

**Files:**
- Modify: `claude/commands/team.md` (thay toàn bộ nội dung)

**Interfaces:**
- Consumes: tên operation `GRILL`/`UPDATE` từ Task 2 (`librarian.md`)
- Produces: không có (file cuối cùng trong chuỗi phụ thuộc)

- [ ] **Step 1: Thay toàn bộ nội dung file**

Dùng Write tool để ghi đè toàn bộ `claude/commands/team.md` với nội dung sau:

```markdown
# Triển khai TeamsCreate với các teammate sau :

## Danh sách team

- leader: .claude/agents/leader.md
- coder: .claude/agents/coder.md
- reviewer: .claude/agents/reviewer.md
- librarian: .claude/agents/librarian.md

# Quy trình làm việc :

- Tất cả mọi công việc trao đổi với teammate trong teams đều thực hiện qua SendMessage trong tmux, không tự tạo subagent mới.

## Vòng lặp chính (coder ↔ reviewer)

Leader giao việc xuống cho coder, coder code xong thì đưa kết quả xuống cho reviewer thực hiện review lại, reviewer thực hiện review đúng với plan thì pass báo với leader là task đã hoàn thành, nếu chưa pass thì đẩy lại task cho coder đến khi nào pass thì thôi, khi leader nhận được báo task hoàn thành sẽ kiểm tra xem còn task nào không nếu còn thì thực hiện tiếp task sau, nếu k còn thì tạm dừng.

## Khi nào gọi librarian

- **Trước khi lập plan cho feature mới / thay đổi kiến trúc đáng kể**: leader gọi librarian (operation GRILL) để hỏi xoáy kiến trúc/thiết kế với user và ghi Decision Log vào `claude/wiki/decisions/`. Leader chỉ tiếp tục brainstorming/write-a-prd/prd-to-issues/writing-plans SAU KHI có Decision Log.
- **Sau khi reviewer pass một task ảnh hưởng kiến trúc/module đáng kể** (không phải task nhỏ vặt): leader gọi librarian (operation UPDATE) để sync `claude/wiki/` phản ánh code thật, tránh State Drift.
- **Task nhỏ** (fix typo, đổi text, tinh chỉnh style...) → không cần gọi librarian.
- Nếu leader không chắc một task có "đáng kể" hay không → hỏi user, không tự quyết.

Hãy nhớ là TeamsCreate và tạo và đánh thức các teammate luôn cho tôi.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "librariann" claude/commands/team.md
```
Expected: không có output (typo đã hết)

Run:
```bash
grep -n "^- librarian:\|Khi nào gọi librarian\|operation GRILL\|operation UPDATE" claude/commands/team.md
```
Expected: 4 dòng match

- [ ] **Step 3: Commit**

```bash
git add claude/commands/team.md
git commit -m "team.md: fix librarian typo, document when leader calls librarian"
```

---

## Final Verification (chạy sau khi cả 5 task xong)

- [ ] **Step 1: Xác nhận cả 5 file đã commit, working tree sạch với các file này**

Run:
```bash
git log --oneline -5
git status --short claude/agents/ claude/commands/team.md
```
Expected: 5 commit gần nhất tương ứng 5 task trên; `git status` không còn thay đổi chưa commit trong `claude/agents/` và `claude/commands/team.md`.

- [ ] **Step 2: Cross-check tên skill nhất quán giữa các file**

Run:
```bash
grep -l "grill-me" claude/agents/*.md
```
Expected: chỉ `claude/agents/librarian.md` (không phải leader/coder/reviewer — grill-me là độc quyền của librarian).

Run:
```bash
grep -l "\`tdd\`" claude/agents/*.md
```
Expected: chỉ `claude/agents/coder.md`.
