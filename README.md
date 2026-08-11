# claude.general — playbook + khung mang đi được cho project mới

Kho này là **hạt giống** để bắt đầu một project mới với kỷ luật tài liệu + git-flow đã đúc kết từ các
project thật (xem đầu `CLAUDE.md`). Không phải lý thuyết — mọi luật đều có tiền lệ/bằng chứng ghi kèm.

## Có gì trong này

| File/thư mục | Vai trò |
|---|---|
| `CLAUDE.md` | Phương pháp luận viết tài liệu — Glossary/ADR/quy mô S-M-L/kỷ luật số. **Auto-load** mỗi phiên Claude Code. |
| `AGENT.md` | Quy tắc vận hành agent — ranh giới hành động, kỷ luật hạ tầng, **§6 tự-review bắt buộc trước khi báo "xong"**. `CLAUDE.md` §0.5 bắt agent đọc file này mỗi phiên. |
| `GIT-FLOW.md` | [OPT] Chi tiết đầy đủ mô hình Issue→worktree→PR→merge (chỉ đọc khi chọn O7-A ở `CLAUDE.md` §11). |
| `templates/` | Copy-paste thẳng vào `docs/` project mới: `glossary.md` · `adr-log.md` · `context-map.md` · `README.md` (doc index) · `roadmap.md` · `HANDOFF.md` · `constitution.md` ([OPT]). |
| `.github/ISSUE_TEMPLATE/` | `agent-ready.yml` (SPEC/PLAN) · `decision-needed.yml` — chỉ cần nếu dùng O7-A. |
| `.github/PULL_REQUEST_TEMPLATE.md` | Checklist bằng chứng trước khi mở PR. |
| `.github/workflows/check.yml` | CI gọi `scripts/check.sh --all` — điền TODO theo ngôn ngữ project. |
| `scripts/check.sh` | Cổng chất lượng — khung 4 bước (syntax/boundary/lint/test), điền TODO. Máy dev VÀ CI gọi CÙNG script này. |
| `scripts/install-hooks.sh` + `scripts/hooks/pre-push` | Cổng kỷ luật ở máy dev (git không version `.git/hooks`, phải tự cài). |

## Bootstrap một project mới — 1 ngày (Sprint 0, `CLAUDE.md` §10)

```bash
# 1. Copy khung vào repo mới
cp claude.general/CLAUDE.md claude.general/AGENT.md <repo-mới>/
cp claude.general/GIT-FLOW.md <repo-mới>/          # chỉ nếu dùng O7-A
mkdir -p <repo-mới>/docs
cp claude.general/templates/*.md <repo-mới>/docs/
cp -r claude.general/.github <repo-mới>/
cp -r claude.general/scripts <repo-mới>/
cd <repo-mới> && ./scripts/install-hooks.sh
```

2. **Thay mọi `<PROJ>`/`<...>`** trong các file vừa copy bằng tên/thông tin project thật.
3. **Điền TODO trong `scripts/check.sh`** theo ngôn ngữ project (syntax/boundary/lint/test thật).
4. **Đọc TOÀN VĂN** mọi bản nháp/khảo sát đang có — Glossary/ADR trích xuất từ đó, không viết từ trí nhớ.
5. Làm theo `CLAUDE.md` §10 (Glossary → 3-5 ADR nền tảng → Context Map → `docs/README.md` → `make check`
   / `./scripts/check.sh`).
6. Chọn quy mô S/M/L (`CLAUDE.md` §2) và 11 tuỳ chọn O1-O11 (`CLAUDE.md` §11) — **ghi lại đã chọn gì**
   vào `docs/README.md`, đừng để phiên sau tự đoán.
7. Nếu >1 repo phụ thuộc chéo: đọc `GIT-FLOW.md` §11c trước khi tạo repo thứ 2 — quyết định monorepo
   hay polyrepo là quyết định thật, ghi lại như một ADR.

## Vì sao tách CLAUDE.md / AGENT.md / GIT-FLOW.md thành 3 file

- `CLAUDE.md` = **VÌ SAO viết tài liệu thế nào** — phương pháp luận, không phụ thuộc project cụ thể.
- `AGENT.md` = **agent được/không được làm gì** — vận hành, ranh giới, bằng chứng-trước-khi-tuyên-bố.
- `GIT-FLOW.md` = **[OPT]** chi tiết mô hình git-as-task-tracker — tách riêng vì nó dài (~400 dòng) và
  chỉ cần khi đã chọn phương án đó; không phải mọi project cần tải nó mỗi phiên.

Một sự thật, một nhà — đúng nguyên tắc L2 mà chính `CLAUDE.md` đề ra cho các project dùng nó.
