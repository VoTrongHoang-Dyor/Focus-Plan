#Setup bộ nhớ wiki + obsidian 


Vai trò của bạn  trong repo này

Trước khi làm bất kỳ task nào: đọc mục "Bản đồ tra cứu" bên dưới để biết nên mở file nào. KHÔNG đọc toàn bộ wiki/ hay toàn bộ codebase cùng lúc — chỉ lấy đúng phần cần, theo tinh thần layered context.

Bản đồ tra cứu (Layered Context)
Kiến trúc tổng thể repo: wiki/architecture.md
Quyết định/PRD đang còn hiệu lực: xem query Dataview bên dưới (mở trong Obsidian) hoặc grep -l "status: Active" wiki/prd/*.md (khi bạn tự tra bằng Read/Grep)
Đang trong giai đoạn khám phá khó (research phase, chưa rõ giải pháp): đọc research.md ở gốc repo trước; nếu chưa có, tạo mới để cache phát hiện thay vì lặp lại việc khám phá ở session sau

TABLE status, date
FROM "wiki/prd"
WHERE status = "Active"
SORT date DESC

Quy tắc bắt buộc
Không tự ý mở/query NotebookLM. NotebookLM là công cụ của người dùng để họ tự tổng hợp lại các PRD — không phải nguồn context cho bạn. Bạn luôn đọc trực tiếp file .md local qua Read/Grep.
Không đọc file có status: Superseded hoặc status: Archived trừ khi người dùng yêu cầu tra lịch sử quyết định cũ.
Khi có yêu cầu tính năng mới / thay đổi kiến trúc đáng kể, chạy đúng pipeline bên dưới theo thứ tự — không nhảy bước.

Pipeline: tính năng mới / thay đổi lớn
Bước 1 — Khảo sát ý tưởng (grill-me)
Dùng skill tại: /Users/hoang_dyor_i/Code_Projects/VoTrongHoang/skills/claude/skills/grill-me/chat.md
Trước khi hỏi câu đầu tiên:
Đọc frontmatter + dòng tóm tắt của mọi PRD status: Active trong wiki/prd/ (không đọc toàn bộ nội dung).

Với PRD Active nào có vẻ liên quan đến ý tưởng mới, explore trực tiếp codebase thật (module/file mà PRD đó mô tả) để kiểm tra PRD còn khớp với code hiện tại không — PRD là ý định, code mới là sự thật. Nếu PRD cũ đã lệch so với code thực tế, đó là tín hiệu xung đột/lỗi thời cần nêu ra, kể cả khi chưa viết PRD mới.
Nếu phát hiện trùng/xung đột (qua PRD text hoặc qua thực tế code), hỏi ngay: "PRD X đang Active có vẻ liên quan/đã lệch so với code hiện tại — bạn muốn PRD mới supersede nó, hay đây là 2 việc độc lập?"

Chỉ sau khi người dùng xác nhận, Claude mới tự sửa frontmatter PRD cũ thành Superseded — không tự gán nhãn khi chưa hỏi. Hỏi xoáy tiếp phần còn lại của ý tưởng đến khi hết fork mở, không hỏi lại điều đã có trong session.

Bước 2 — Lưu Decision Log

Ghi output bước 1 vào wiki/decisions/<slug>-decision-log.md, frontmatter:

status: Active
date: <ngày tạo>


Bước 3 — Chia nhỏ issues (prd-to-issues)

Dùng skill tại: /Users/hoang_dyor_i/Code_Projects/VoTrongHoang/skills/claude/skills/prd-to-issues/SKILL.md

Lưu ý: tôi đoán tên file entry là SKILL.md theo convention chung — tôi không truy cập được máy bạn nên chưa xác minh được tên file thật trong folder prd-to-issues. Kiểm tra lại và sửa đường dẫn này nếu khác.

Input: Decision Log ở bước 2. Output: danh sách issue, giải quyết/triển khai từng issue.

Bước 4 — Soạn PRD đầy đủ (write-a-prd)

Dùng skill tại: /Users/hoang_dyor_i/Code_Projects/VoTrongHoang/skills/claude/skills/write-a-prd/SKILL.md

Tương tự bước 3 — xác minh lại tên file entry thật trong folder write-a-prd.

Input: Decision Log + issues đã giải quyết ở bước 3. Output: PRD lưu vào wiki/prd/<slug>.md, frontmatter:

status: Active
date: <ngày tạo>
supersedes: <slug PRD cũ, nếu có>
Nếu PRD này thay thế PRD cũ → đổi status của PRD cũ thành Superseded.

Bước 5 — Sync vào wiki

Không cần thao tác thêm — PRD ở bước 4 đã nằm trong wiki/prd/, Dataview query đầu file này tự động thấy nó vì status: Active.

Bước 6 — NotebookLM (người dùng tự làm, bạn chỉ nhắc)

Kết thúc pipeline bằng câu nhắc, không tự động thực hiện:

"PRD mới đã sẵn sàng tại wiki/prd/<slug>.md. Bạn tự upload vào NotebookLM notebook của repo này nếu muốn tổng hợp/review lại sau."

Cấu trúc thư mục chuẩn cho repo này

repo-root/
├── CLAUDE.md              ← chính là file này
├── research.md            ← cache phát hiện từ các giai đoạn khám phá khó
└── wiki/
    ├── architecture.md
    ├── decisions/
    │   └── <slug>-decision-log.md
    └── prd/
        └── <slug>.md      ← frontmatter status: Active/Superseded/Archived
Mỗi repo có wiki/ riêng bên trong chính nó + 1 NotebookLM notebook riêng — không dùng chung wiki trung tâm giữa các repo.

Ghi nhớ triết lý (để không lặp lại lỗi cũ)
Wiki cũ từng phình quá 300k token vì nội dung khó kiểm chứng, cấu trúc xung đột → mọi trang trong wiki/decisions/ và wiki/prd/ PHẢI có frontmatter status, không được để mồ côi.
Không ai tự tay gắn nhãn status, và Claude không tự ý gắn nhãn một mình. PRD chỉ đáng tin khi được validate qua codebase thật (không phải vì được ghi trong markdown) — vì vậy grill-me luôn explore code trước khi hỏi xoáy, và chỉ đổi status: Superseded sau khi người dùng xác nhận.
Đừng nạp cả wiki/ vào context một lần — chỉ đọc đúng file theo Bản đồ tra cứu hoặc Dataview query ở trên.
NotebookLM không phải nguồn context cho Claude — chỉ để người dùng tự tổng hợp; đừng thêm bước gọi NotebookLM qua Claude-in-Chrome vào pipeline này.
