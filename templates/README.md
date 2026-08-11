# <PROJ> — Doc Index

> Bản đồ đọc cho toàn bộ tài liệu. Người mới (và agent phiên sau) đọc file này TRƯỚC bất kỳ file nào khác.

> **Quy mô tài liệu (theo `CLAUDE.md` §2):** mức **<S/M/L>** — <1 câu lý do>. Lên mức kế tiếp khi
> <trigger cụ thể>.
>
> **Đã chọn (`CLAUDE.md` §11):** O1-<?> · O2-<?> · O3-<?> · O4-<?> · O5-<?> · O6-<?> · O7-<?> · O8-<?> ·
> O9-<?> · O10-<?> · O11-<?>. (Xoá dòng này nếu dùng nguyên khuyến nghị mặc định ở cuối §11.)

## Tier 0 — đọc trước tiên

- **[glossary.md](glossary.md)** — Ubiquitous Language, mỗi mục có ID.
- **[adr-log.md](adr-log.md)** — quyết định + lý do + phương án đã loại.
- **[context-map.md](context-map.md)** — ranh giới hệ thống (hoặc: gộp trong `<file khác>` §<n>, xem
  ghi chú ở đó).

## Tài liệu theo nhu cầu

1. **[<project-overall.md>](<project-overall.md>)** — <câu hỏi nó trả lời>.
2. **[<algorithm.md>](<algorithm.md>)** — <câu hỏi nó trả lời>.
3. **[<testing-and-eval.md>](<testing-and-eval.md>)** — <câu hỏi nó trả lời>.

> **Đang tiếp tục việc dở?** Đọc [`HANDOFF.md`](HANDOFF.md) trước — trạng thái phiên gần nhất, việc
> đang dở, việc kế tiếp. File ngắn, sống-ngắn; nguồn sự thật đầy đủ vẫn là `<roadmap>.md §TODO`.

## Quy tắc vận hành agent

[`../AGENT.md`](../AGENT.md) — ranh giới hành động · kỷ luật đổi hạ tầng/bảo mật · nơi ghi issue ·
commit/push · **§6 bằng chứng trước khi tuyên bố (tự-review bắt buộc)**. Đọc trước khi đổi hạ tầng hoặc
đóng một TODO — `CLAUDE.md` §0.5 bắt agent đọc file đó đầu mỗi phiên, không cần user nhắc lại.
