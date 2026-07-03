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

- **Trước khi lập plan cho feature mới / thay đổi kiến trúc đáng kể**: leader gọi librarian (operation GRILL) để hỏi xoáy kiến trúc/thiết kế với user và ghi Decision Log vào `.claude/wiki/decisions/`. Leader chỉ tiếp tục brainstorming/write-a-prd/prd-to-issues/writing-plans SAU KHI có Decision Log.
- **Sau khi reviewer pass một task ảnh hưởng kiến trúc/module đáng kể** (không phải task nhỏ vặt): leader gọi librarian (operation UPDATE) để sync `.claude/wiki/` phản ánh code thật, tránh State Drift.
- **Task nhỏ** (fix typo, đổi text, tinh chỉnh style...) → không cần gọi librarian.
- Nếu leader không chắc một task có "đáng kể" hay không → hỏi user, không tự quyết.

## Cách tạo team thật (implementation của "TeamsCreate")

Không có tool riêng tên `TeamsCreate` trong harness hiện tại — tham số `team_name` của tool `Agent` đã bị deprecated với ghi chú "The session has a single implicit team". Vì vậy "TeamsCreate" được hiện thực bằng:

1. Gọi tool `Agent` một lần cho mỗi teammate (`leader`, `coder`, `reviewer`, `librarian`), đặt `name` đúng 4 tên này để có thể `SendMessage` gọi lại theo tên. Vì các agent này chưa được đăng ký như `subagent_type` riêng trong harness (chỉ tồn tại dưới dạng file cấu hình ở `.claude/agents/*.md`), dùng `subagent_type: general-purpose` và dán nguyên nội dung file agent tương ứng vào đầu `prompt` để teammate đó đóng đúng vai.
2. Toàn bộ teammate được spawn trong cùng phiên tự động thuộc "1 implicit team" của session — không cần (và không thể) tạo team riêng biệt.
3. Từ đó, mọi trao đổi giữa các teammate dùng `SendMessage({ to: <tên teammate> })` theo đúng vòng lặp coder ↔ reviewer ở trên — không tự tạo thêm subagent mới ngoài 4 teammate đã spawn.

Hãy nhớ luôn tạo và đánh thức các teammate theo cơ chế trên cho tôi.