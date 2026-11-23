# MULTI-REPO.md — Hệ sinh thái nhiều repo (companion của CLAUDE.md + GIT-FLOW.md)

> **File này là gì:** phần mở rộng **[OPT]**, trước đây là `GIT-FLOW.md` §11c. Tách ra ngày 2026-11-23 để
> project chỉ có một repo không phải tải khoảng 80 dòng này mỗi lần đọc GIT-FLOW. Giữ nguyên số mục §11c
> (L3: ID không đánh lại), nên các trích dẫn cũ "§11c" vẫn trỏ đúng nội dung.
> **[TRIGGER] đọc file này khi:** ≥2 repo **thật sự phụ thuộc lẫn nhau** (chi tiết ngay dưới), hoặc
> **trước khi tạo repo thứ 2** cho cùng một hệ.
> **Phụ thuộc:** `CLAUDE.md` (L1–L4, §2 quy mô) · `GIT-FLOW.md` §11b (Issue/PR, `agent-ready`, CI).

## 11c. [OPT] Hệ sinh thái nhiều repo — khi `GIT-FLOW.md` §11b phải trải ra trên >1 repo

★ **Cảnh báo mức bằng chứng (theo L6 ở CLAUDE.md):** khác với §11b — vốn mô tả một hệ thống đang chạy
thật — mục §11c này là **tổng hợp từ khảo sát thực hành ngành + suy luận logic**, chưa có xác nhận đã
chạy đúng nguyên trạng trong một project cụ thể. Áp dụng thật thì tự thêm dòng "đã verify ngày <DATE>"
theo L5, đừng đọc nó với cùng mức tin cậy như phần quan sát được.


**[TRIGGER] kích hoạt mục này khi:** ≥2 trong số các repo **thật sự phụ thuộc lẫn nhau** — đổi API/schema
ở repo này thường kéo theo việc phải đổi ở repo kia. **Chưa cần** nếu 3 project chỉ tình cờ cùng một
người quản lý nhưng độc lập hoàn toàn (không gọi nhau, không chia schema) — lúc đó áp `GIT-FLOW.md` §11b riêng cho
từng repo là đủ, đừng phức tạp hoá.

### Bước 0 — quyết định monorepo hay polyrepo, và **ghi lại như một ADR**

Đây không phải câu hỏi công cụ, mà là đánh đổi thật, và nên trace được như mọi quyết định khác (L1–L4):

| | Monorepo (gộp 3 vào 1 repo) | Polyrepo (giữ 3 repo riêng) |
|---|---|---|
| Agent thấy được gì | Toàn bộ 3 project trong một context — sửa xuyên repo trong **một PR** | Agent ở repo A không thấy ai đang tiêu thụ code nó vừa sửa; đổi xuyên repo cần điều phối thêm |
| Chi phí hạ tầng | Phải đầu tư liên tục (build cache, CI phân vùng theo thư mục) theo kịp quy mô, không thì PR review time giãn ra không đoán được | Mỗi repo tự chủ CI/release riêng, chi phí hạ tầng thấp hơn nhưng đổi xuyên repo cần N PR đồng bộ |
| Hợp khi | 3 project phụ thuộc chéo nhiều, đổi thường kéo cả 3, bạn là người/agent duy nhất vận hành | 3 project release lệch nhịp nhau, sau này có thể tách quyền truy cập/đội ngũ riêng cho từng cái |
| Không hợp khi | Bạn chưa sẵn sàng đầu tư tooling build/CI phân vùng — monorepo không tự nhiên rẻ | 3 project đổi API cùng lúc thường xuyên — chi phí điều phối N-PR ăn hết lợi ích tách repo |

★ Mặc định đề xuất cho "một người + agent, 3 project phụ thuộc chéo, tốc độ cao": **monorepo** — agent
sửa xuyên 3 project trong một PR, một `make check` chạy được cả 3. Đổi ý sau này (tách ra) vẫn dễ hơn
chiều ngược lại.

Nếu chọn polyrepo, phần dưới đây áp dụng.

### Một repo "hub" giữ Tier 0 — các repo code chỉ LINK, không copy

Vi phạm L2 điển hình khi có nhiều repo: mỗi repo tự có một bản `glossary.md`/`adr-log.md` riêng, rồi
lệch nhau dần. Xử lý: tạo một repo thứ 4 (`<eco>-docs`), chuyển toàn bộ Tier 0 — `glossary.md`,
`adr-log.md`, `context-map.md`, `constitution.md` (`GIT-FLOW.md` §11b), `README.md` (Doc Index) — về đó. Mỗi repo code
chỉ giữ một file mỏng trỏ sang:

```markdown
<!-- docs/POINTER.md trong từng repo con -->
Tài liệu nền tảng của hệ sinh thái sống ở <eco>-docs, KHÔNG lặp lại ở đây:
- Glossary: <link> · ADR Log: <link> · Context Map: <link> · Constitution: <link>
Tài liệu CHỈ RIÊNG repo này (algorithm.md, interface.md...) vẫn ở docs/ như bình thường.
```

**Context Map đổi vai trò:** trước đây (1 repo) nó vẽ ranh giới với thế giới ngoài; giờ nó vẽ **ranh
giới giữa 3 project của chính bạn** — cái gì thuộc repo nào, ai gọi ai, qua hợp đồng nào (Interface
Control Document — Tier 2/3, không còn là tuỳ chọn ở mức M, xem §4).

### ID cấp hệ sinh thái — thêm một tầng, không thay tầng cũ

`GLOSS-<PROJ>-001` chỉ có nghĩa trong phạm vi 1 project. Thêm tầng `GLOSS-ECO-001` cho thuật ngữ **dùng
chung cả 3** (tên miền nghiệp vụ, thực thể xuyên repo); giữ nguyên `GLOSS-<PROJ>-001` cho thuật ngữ chỉ
riêng 1 repo. Cùng quy tắc cho `ADR-ECO-*` (quyết định ảnh hưởng ≥2 repo, vd chọn giao thức giữa các
service) so với `ADR-<PROJ>-*` (quyết định nội bộ 1 repo).

### Issue liên-repo — `Closes owner/repo#N` phải viết rõ, không tự nhiên hoạt động

`Closes #NN` trong PR chỉ tự đóng Issue **cùng repo**. GitHub hỗ trợ `Closes owner/repo-khac#12` để đóng
Issue ở repo khác, nhưng nếu không quy ước rõ trong template `agent-ready`, Issue liên-repo sẽ bị quên.
Thêm một trường bắt buộc vào SPEC (`GIT-FLOW.md` §11b) khi việc động tới >1 repo: **"Repo liên quan"** — liệt kê hết,
mỗi repo một Issue riêng, trỏ nhau bằng `Blocked by owner/repo#N` / `Blocks owner/repo#N`.

### CI dùng chung — reusable workflow, không copy-paste YAML

Đặt `scripts/check.sh` (G1) và
workflow gốc trong repo hub hoặc một repo `.github` cấp tổ chức, 3 repo con gọi lại bằng:
```yaml
jobs:
  check:
    uses: <org>/<eco>-docs/.github/workflows/check.yml@main
```
Một nơi định nghĩa cổng, ba nơi gọi — đúng nguyên tắc "CI chạy đúng script mà người chạy ở máy" (bảng
quyết định ở `GIT-FLOW.md` §11b), chỉ mở rộng từ 1 repo ra N repo.

### Khi nào tính lại quy mô S→M

Có hệ sinh thái ≥2 repo phụ thuộc chéo là điều kiện "domain thứ 2 sắp lên" trong bảng §2 đã xảy ra thật
— tự động đẩy quy mô tài liệu từ **S lên M**: Tier 0 tách file hẳn (không gộp như mức S nữa), PR review
bắt buộc cho `docs/**` ở repo hub, Doc Index có trạng thái Draft/In Review/Approved.
