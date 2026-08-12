# CLAUDE.md — Cách dựng bộ TÀI LIỆU cho một project (playbook mang đi được)

> **File này là gì:** phương pháp luận viết tài liệu, **không gắn với một project cụ thể**. Chép nguyên
> file này sang repo mới, thay `<PROJ>` bằng tên project, rồi làm theo §10 (Sprint 0 trong 1 ngày).
> **File này KHÔNG phải:** quy tắc vận hành agent (ranh giới hành động, kỷ luật hạ tầng, commit/push,
> tự-review trước khi báo "xong") — thứ đó thuộc `AGENT.md`/`AGENTS.md` cạnh nó, và §0.5 ngay dưới đây
> bắt agent đọc nó mỗi phiên. Hai file, hai việc, đừng trộn.
>
> **Nguồn đúc kết:** hai bộ tài liệu **có thật, đang vận hành**, ở hai quy mô đối lập — (a) bộ ~6 tài
> liệu gọn, bám sát code, mọi tuyên bố kèm lệnh verify, của một project do **một người + agent AI** làm
> với tốc độ cao; (b) bộ ~27 tài liệu đánh số theo tầng, Glossary có ID, ADR theo Nygard, traceability
> matrix, quy trình duyệt đầy đủ. Không bộ nào "đúng hơn" bộ nào — chúng đúng với quy mô của chúng.
> §2 dạy cách **chọn quy mô**, thay vì chép mù một bộ.

**Mục lục:** §0 cách đọc · **§0.5 bootstrap `AGENT.md` [BẮT BUỘC]** · **§1 bảy luật bất di bất dịch** · §2
chọn quy mô S/M/L · §3 Tier 0 (4 file luôn có) · §4 danh mục theo tầng · §5 khuôn mẫu copy-paste · §6 kỷ
luật số · **§6b minh bạch/provenance/độ tin cậy cho pipeline AI dày đặc** · §7 vòng đời + DoD · §8 ép
bằng máy · §9 tra triệu chứng→luật · §10 Sprint 0 · **§11 các tuỳ chọn [OPT]** · §11b git làm hệ quản lý
việc (chi tiết ở **`GIT-FLOW.md`** cạnh file này — chỉ đọc khi đã chọn O7-A) · §12 ba thứ không nên làm.

> **Bắt đầu project mới?** Đừng chỉ chép file này — có sẵn bộ khung copy-paste đầy đủ (AGENT.md ·
> `templates/` · `.github/` issue-forms + PR template + workflow CI) trong repo chứa file này
> ([claude.general](https://github.com/Jester6136/claude.general)). Xem `README.md` ở gốc repo đó để
> bootstrap trong 1 ngày theo §10.

## 0. Cách đọc file này — phân biệt BẮT BUỘC với TUỲ CHỌN

| Nhãn | Nghĩa |
|---|---|
| **[BẮT BUỘC]** | Bất di bất dịch. Áp cho mọi project, mọi quy mô. Bỏ là mất tính kín kẽ, không phải "tối giản". |
| **[OPT]** | Tuỳ chọn có đánh đổi. **§11** liệt kê 11 điểm chọn + điều kiện. Chọn xong **ghi lại đã chọn gì** ở `docs/README.md` — nhất quán quan trọng hơn phương án. |
| **[TRIGGER]** | Chưa làm bây giờ, nhưng đã ghi rõ **điều kiện** kích hoạt. Hoãn mà không có trigger = quên. |

**Về mức độ chắc chắn — nói thẳng để bạn tự cân:**
- Luật L1–L4 và bộ chuẩn ở §4 là **thực hành ngành đã được chuẩn hoá** (DDD Ubiquitous Language, ADR
  Nygard, ISO 29148/25010/42010). Không phải phát minh của file này.
- Luật L5–L7 và §6 (kỷ luật số) đúc từ **sự cố quan sát trực tiếp** trên 2 project — mẫu nhỏ (n=2), nên
  hãy đọc chúng như *"đây là lỗi có thật, đây là cơ chế chặn"*, không phải quy luật phổ quát. Mỗi chỗ có
  ghi rõ tiền lệ để bạn tự đánh giá nó có áp vào bối cảnh của bạn không.
- Con số cụ thể trong file (66,4%→45,0%; 84/125 tệp; 90,5%; 337 lỗi lint) là **số đo thật đã ghi lại**,
  không phải ví dụ minh hoạ. Chúng đứng ở đây với vai trò *bằng chứng rằng lỗi kiểu đó xảy ra thật* —
  đừng chép sang project của bạn như thể là chỉ tiêu.

## 0.5. [BẮT BUỘC] Bootstrap `AGENT.md` — lý do file này phải nằm NGAY ĐẦU CLAUDE.md

`CLAUDE.md` được Claude Code **tự động tải mỗi phiên**; `AGENT.md`/`AGENTS.md` (quy tắc vận hành —
ranh giới hành động, kỷ luật hạ tầng, commit/push, §6 bằng chứng-trước-khi-tuyên-bố) thì **KHÔNG** tự
tải — nó chỉ có tác dụng nếu có ai/cái gì nhắc agent đọc nó. Đặt dòng này ở đây, không phải cuối file,
vì "đọc trước khi làm gì cả" chỉ đúng nghĩa khi nó là điều ĐẦU TIÊN agent thấy:

> **Nếu repo này có `AGENT.md` (hoặc `AGENTS.md`) ở gốc, ĐỌC NÓ trước khi code/sửa tài liệu bất kỳ việc
> gì trong phiên này** — kể cả khi user không nhắc. File đó chứa ranh giới hành động và bước tự-review
> bắt buộc trước khi báo "xong". Không có file đó ⇒ bỏ qua bước này, không tự bịa ra quy tắc.

Đây là cơ chế khiến kỷ luật "chỉnh chu" xảy ra **ở MỌI phiên/mọi trao đổi**, không phụ thuộc agent có
nhớ lại từ hội thoại trước hay không — vì `CLAUDE.md` (nơi câu lệnh này nằm) luôn được tải, còn trí nhớ
hội thoại thì không.

---

## 1. Bảy luật bất di bất dịch (không phụ thuộc quy mô)

Đây là phần **kỷ luật**, không phải khối lượng — project 1 người hay 10 người đều áp như nhau.

### L1. [BẮT BUỘC] Ba artifact NỀN TẢNG viết trước tiên, không theo thứ tự đánh số
**Glossary → ADR nền tảng → Context Map.** Mọi tài liệu khác phái sinh từ ba thứ này.

- **Glossary trước:** không khoá tên gọi thì mỗi tài liệu sau sẽ diễn giải lệch đi một chút. Dấu hiệu
  cần Glossary gấp: cùng một khái niệm đang có 2–3 tên trong các bản nháp (*"Rule Registry" vs "Rule
  Engine" vs "Business Rule Validator"*).
- **ADR nền tảng ngay sau Glossary:** thường **đã tồn tại sẵn** trong bản nháp dưới dạng văn xuôi — việc
  cần làm là **đóng khung + cấp ID**, không phải sáng tác. Chỉ 3–5 ADR trả lời được câu *"hệ này là gì,
  không là gì"*.
- **Context Map sau cùng trong ba:** vẽ ranh giới (Bounded Context + quan hệ) **sau khi** đã có ADR để
  trích dẫn. Vẽ trước ADR là vẽ theo cảm tính.

> Ba bước này thường xong trong 1 ngày–1 tuần vì nội dung đã nằm rải rác sẵn; công việc là **trích xuất,
> hợp nhất, cấp ID**.

### L2. [BẮT BUỘC] Một loại sự thật — MỘT nơi định nghĩa gốc, nơi khác chỉ LINK
Thuật ngữ chỉ định nghĩa ở Glossary. Lý do quyết định chỉ nằm ở ADR. Trạng thái việc chỉ nằm ở
roadmap/backlog. Tài liệu khác **trích dẫn** (`xem ADR-<PROJ>-003`), **không kể lại**.

Vi phạm điển hình cần bắt trong review: một bảng tra cứu tự "làm giàu" thêm mô tả không có ở nguồn gốc.
Nó tạo ra sự thật thứ hai, và sự thật thứ hai luôn là cái cũ đi.

### L3. [BẮT BUỘC] ID bất biến — không bao giờ renumber
`GLOSS-<PROJ>-001`, `ADR-<PROJ>-001`, `FR-1.2`, `RISK-<PROJ>-019`. Thêm mục mới thì **nối vào cuối dãy**
kể cả khi về mặt khái niệm nó thuộc nhóm ở giữa. Renumber làm hỏng mọi trích dẫn đã có — thà ID xếp
"không đẹp" còn hơn trace gãy. ID Superseded thì giữ nguyên, không tái sử dụng số.

### L4. [BẮT BUỘC] Tài liệu đã chốt là BẤT BIẾN — trừ khi qua ADR mới
Nhưng "bất biến" đọc theo nghĩa đen quá rộng sẽ làm tê liệt. Phân **4 loại thay đổi**, chỉ loại 4 cần ADR:

| Loại | Là gì | Xử lý | Bump |
|---|---|---|---|
| 1 | Sửa **lỗi khách quan** (sai chính tả, cross-ref sai số, chữ ký hàm lỗi thời) | Sửa thẳng | PATCH |
| 2 | **Bổ sung thuần tuý** (thêm thuật ngữ/yêu cầu mới, điền ô "—" khi tài liệu nguồn đã có) | Sửa thẳng | MINOR |
| 3 | **Câu hỏi còn mở** (chưa đủ căn cứ để chốt) | Ghi vào Risk Register / mục "khoảng trống", **không** tự quyết | — |
| 4 | **Đảo ngược một quyết định đã chốt** | **Bắt buộc ADR mới** + link 2 chiều, ADR cũ chuyển `Superseded` (giữ nguyên nội dung) | MINOR/MAJOR |

★ Mỗi lần bump, ghi **một dòng lý do ngay trong header tài liệu**: bump gì, vì sao, phát hiện lúc nào.
Chuỗi lý do đó chính là trí nhớ của project — đắt hơn nội dung nhiều lần.

### L5. [BẮT BUỘC] Bằng chứng thay vì tuyên bố
Câu *"đã xong / chắc chạy được"* không có giá trị tài liệu. Mọi mục đóng phải kèm **lệnh thật + kết quả
thật**:

```
**Verify:** `docker compose exec <service> python -m <module>` → OK ·
`lint-imports` → 5 kept, 0 broken · endpoint `/metrics` trả `denominator=5` (gọi **qua lớp proxy của
dashboard**, tức đúng đường người dùng đi — không chỉ gọi thẳng backend).
```

Ba biến thể phải phân biệt rõ trong tài liệu: `⬜ chưa làm` · `🔨 code xong CHƯA verify` · `✅ code+verify`.
Gộp ba thứ này thành "done" là cách nhanh nhất để tài liệu bắt đầu nói dối.

### L6. [BẮT BUỘC] Tài liệu nào CÓ THỂ nói dối thì phải TỰ CẢNH BÁO
File trạng thái (`HANDOFF.md`, `PROGRESS.md`) luôn cũ hơn thực tế. Bắt buộc đặt ngay đầu file:

```markdown
> ⚠ĐỪNG TIN NGUYÊN VĂN file này — luôn đối chiếu `git log` / issue tracker / code thật trước khi hành
> động. Nguồn sự thật đầy đủ là <roadmap §TODO>; file này chỉ là con trỏ, sống-ngắn.
```

### L7. [BẮT BUỘC] Bất biến nào ÉP ĐƯỢC BẰNG MÁY thì đừng để nằm trong văn xuôi
Một câu trong tài liệu không chặn được ai. Chuyển thành ràng buộc kiểm được (§8). Câu hỏi tự vấn mỗi khi
viết một dòng "phải/không được": *"dòng này có thể thành một check trong `make check` không?"* — nếu có,
viết check, rồi tài liệu chỉ còn nhiệm vụ giải thích **vì sao**.

---

## 2. Chọn QUY MÔ bộ tài liệu — đừng chép mù

Áp bộ 70 tài liệu vào project một người = tạo ra phần lớn tài liệu không ai đọc. Áp bộ 6 file vào
platform nhiều team = mất trace. Chọn theo bảng, và **ghi rõ mình đang ở mức nào**:

| Mức | Khi nào | Bộ tài liệu | Quy trình |
|---|---|---|---|
| **S** | 1 người (± agent), 1 service, tốc độ dev cao, chưa có team | **Tier 0 (4 file, §3) + 5–6 doc canon** gộp nhiều vai trong một file | Sửa thẳng trên nhánh dev; ADR vẫn bắt buộc cho L4-loại-4 |
| **M** | 2–5 người, hoặc có consumer ngoài (API/SDK), hoặc domain thứ 2 sắp lên | Tier 0 tách file + Tier 1–3 (§4), ~12–15 tài liệu | PR review cho `docs/**`; Doc Index có trạng thái Draft/In Review/Approved |
| **L** | Nhiều team, audit/compliance, hợp đồng liên hệ thống | Bộ đánh số đầy đủ theo tầng (~20–30), Traceability Matrix, Quality Attribute Scenarios | Discussion → Issue → PR → merge = Approved; CI check tài liệu |

**Nguyên tắc "hoãn phải có địa chỉ":** mỗi thứ chưa làm phải ghi kèm **TRIGGER** cụ thể — nếu không nó
biến mất khỏi trí nhớ:

```markdown
⏸ **Hoãn — Trigger A:** bộ thuật ngữ multi-tenancy chi tiết (Tenant tách khỏi Domain, Isolation Level)
chỉ bổ sung khi **domain thứ 2 thật sự onboard**. Hiện `Quota` (GLOSS-<PROJ>-015) đủ dùng như khái niệm gộp.
```

**Không copy từ mức L xuống mức S:** quy trình Discussion→Issue→ADR→PR + "tài liệu Approved bất biến
tuyệt đối" là **tự trói** khi chỉ có một người và tốc độ dev cao. Giữ *kỷ luật* (ADR, ID, SSOT), bỏ
*thủ tục* (nhiều cổng duyệt).

---

## 3. TIER 0 — bốn file LUÔN CÓ, bất kể quy mô

Ở mức S có thể để chung một thư mục phẳng; ở mức M/L tách `docs/design/`.

| # | File | Vai trò | Không có nó thì |
|---|---|---|---|
| 1 | `glossary.md` | Ubiquitous Language, mỗi mục có ID + trạng thái 🔒Locked/🟡Proposed | Mỗi tài liệu tự bịa tên riêng |
| 2 | `adr-log.md` | Quyết định + **lý do** + phương án đã loại | 6 tháng sau không ai biết vì sao chọn thế, và sẽ chọn lại sai |
| 3 | `context-map.md` | Ranh giới hệ thống: cái gì trong, cái gì ngoài, quan hệ gì | Code lõi từ từ ngấm tri thức nghiệp vụ của một domain |
| 4 | `README.md` (Doc Index) | Bản đồ đọc: có gì, đọc thứ tự nào, ai cập nhật khi nào | Người mới (và agent phiên sau) đọc lung tung rồi kết luận sai |

**Thêm ở mức S — hai file rất đáng giá** (rút từ vận hành thực tế):

| File | Vai trò |
|---|---|
| `roadmap.md` §TODO (một file lộ trình duy nhất) | **MỘT** nơi ghi mọi vòng "raise issue → fix → verify". **Không** tạo `ISSUES.md`/`CHANGELOG.md` rời — phân mảnh tri thức là cách mất nó |
| `HANDOFF.md` | Trạng thái phiên: *vừa xong / **đang dở** / việc kế*. Sống-ngắn, có cảnh báo L6. Cứu đúng lúc context bị nén hoặc đổi người |

---

## 4. Danh mục tài liệu theo tầng (mức M/L)

Đọc từ trên xuống để hiểu **tại sao**; đọc từ dưới lên để biết **làm thế nào**. Reviewer chỉ cần Tier 0–1;
engineer implement chỉ cần Tier 3 — miễn là nó trace ngược lên được.

```
TIER 0 — GOVERNANCE & META
  Doc Index · Glossary · ADR Log · Traceability Matrix
TIER 1 — BUSINESS & REQUIREMENTS            (ISO/IEC 29148)
  Vision & Scope · Functional Requirements · Context Map (DDD) · Non-Functional Req (25010)
TIER 2 — ARCHITECTURE                       (ISO/IEC/IEEE 42010 · C4 + 4+1)
  Architecture Description · Interface Control (API contract) · Data Architecture ·
  Security & Compliance (27001 nếu có PII) · Quality Attribute Scenarios
TIER 3 — DETAILED DESIGN
  Component/Pipeline Spec · API Spec (OpenAPI) · Sequence Diagrams · Error Catalog
TIER 4 — QUALITY & OPERATIONS
  Test Strategy + cách verify NFR · Risk Register · Deployment/Rollout · Runbook
```

**Cách nén 5 tầng trên xuống ~6 file ở mức S** — mỗi file GỘP nhiều tầng, nhưng **không tầng nào biến mất**:

| File mức S (tên gợi ý) | Gộp tầng nào | Trả lời câu hỏi |
|---|---|---|
| `project-overall.md` | Tier 1 + Context Map | Hệ thống này là gì, giải bài toán gì, ranh giới tới đâu |
| `algorithm.md` | Tier 2–3 (cơ chế + **bất biến**) | Nó chạy thế nào, cái gì luôn-đúng, hỏng thì hỏng ở đâu |
| `interface.md` (hoặc OpenAPI) | Tier 2–3 hợp đồng | Gọi vào bằng gì, trả ra gì, lỗi có mã nào |
| `ui-ux.md` | Tier 3 phía người dùng | Người dùng thấy gì, thao tác nào, hiển thị số liệu ra sao |
| `testing-and-eval.md` | Tier 4 chất lượng | Đo bằng gì, ngưỡng nào là đạt, chạy ở đâu |
| `runbook.md` | Tier 4 vận hành | Deploy/rollback thế nào, cháy thì làm gì |

⇒ **Gộp file là hợp lệ; bỏ TẦNG mới là mất mát.** Trước khi bỏ, hỏi: *tầng này ai đọc, lúc nào?*
Không trả lời được thì hoãn kèm trigger (§2).

**Chuẩn nên mượn** (nhẹ, không tạo overhead riêng): ISO 29148 (requirements) · ISO 25010 (8 nhóm chất
lượng cho NFR) · ISO 27001 (**bắt buộc, không tuỳ chọn** nếu chạm dữ liệu cá nhân) · C4 + 4+1 (vẽ
Mermaid) · DDD strategic (Bounded Context/Context Map) · ADR Nygard.
**Không dùng TOGAF** ở quy mô một service — tạo tài liệu governance không ai đọc.

---

## 5. Khuôn mẫu copy-paste

### 5.1 Header chuẩn của mọi tài liệu
```markdown
# <Tên tài liệu> — <PROJ>

> **Mã:** <PROJ>-DOC-02 | **Phiên bản:** 0.3.0 | **Ngày:** YYYY-MM-DD | **Trạng thái:** 🟢 Approved
> **Lịch sử bump:** 0.2.0→0.3.0 (YYYY-MM-DD, <nguồn: issue/chat/phát hiện>): <đổi gì + VÌ SAO + phát
> hiện lúc nào>. Loại <1|2|4> theo CLAUDE.md §L4 ⇒ <cần/không cần> ADR.
> **Depends On:** <PROJ>-DOC-01 (Glossary) — Approved
> **Nguồn:** <tài liệu/khảo sát/URL đã đọc TOÀN VĂN — không ghi nguồn chưa đọc>
```

### 5.2 Mục từ Glossary
```markdown
| ID | Thuật ngữ | Định nghĩa | Trạng thái | Nguồn |
|---|---|---|---|---|
| GLOSS-<PROJ>-007 | Confidence Score | Điểm [0,1] do engine gán cho một giá trị trích xuất; KHÔNG phải xác suất đúng — chỉ dùng để xếp hạng và định tuyến | 🔒 Locked | ADR-<PROJ>-004 |
```
Kèm một mục **"Nhập nhằng đã giải quyết"**: hai khái niệm trùng tên nhưng khác nghĩa phải nói thẳng
(*Risk Tier của Field* ≠ *tên tier `critical`/`normal` trong ngưỡng config* — chính nhầm lẫn này từng làm
lệch cả một story).

### 5.3 ADR (Nygard)
```markdown
## ADR-<PROJ>-001: <Quyết định, viết ở thể khẳng định>
**Trạng thái:** Accepted (<PR/chat>, YYYY-MM-DD) | **Ngày:** YYYY-MM-DD

### Bối cảnh
<Vì sao phải quyết BÂY GIỜ. Rủi ro 2 chiều nếu chọn sai.>

### Phương án đã xem xét
| Phương án | Mô tả | Đánh giá |
|---|---|---|
| (a) … | … | **Chọn** — <lý do> |
| (b) … | … | Loại — <lý do CỤ THỂ, dẫn bằng chứng> |
| (c) … | … | Loại (chưa tới lúc) — Trigger B |

### Quyết định
<Chọn gì. Cơ chế hiện thực hoá nằm ở ADR nào.>

### Hệ quả
- **Tích cực:** …
- **Tiêu cực:** … (phải có — ADR không có mặt trái là ADR chưa nghĩ đủ)
- **Ràng buộc mới bắt buộc:** <thứ ép được bằng máy thì nói rõ, xem §8>
- **Liên quan:** ADR-…, DOC-…
```

### 5.4 Mục TODO / nhật ký sửa (mức S — dùng hằng ngày)
```markdown
- [x] **🔴 <tên ngắn>** — ✅ **code+verify YYYY-MM-DD** (<repo>, `<file>`): <gốc rễ + fix, 1–2 câu>.
      **Verify:** <lệnh thật → kết quả thật>. ⚠**Còn:** <phần dở, nếu có>.
      ★<bài học dễ lặp ở chỗ khác>
```

### 5.5 HANDOFF
```markdown
# HANDOFF — <ngày>
> ⚠Đừng tin nguyên văn — đối chiếu `git log`/code thật. Nguồn đầy đủ: <roadmap §TODO>.
## 1. Vừa xong   ## 2. ĐANG DỞ (việc kế tiếp ngay + thứ đã kiểm sẵn)   ## 3. Việc còn mở
## 4. Tham chiếu ngoài   ## 5. Trạng thái hạ tầng (đã verify <ngày>)
```
★ Mục 2 phải ghi cả **những gì đã kiểm sẵn** (danh sách bất biến đã grep, cấu trúc đã soi) — phiên sau
không phải làm lại từ đầu.

---

## 6. Kỷ luật SỐ trong tài liệu (phần hay bị bỏ quên nhất)

Áp cho **mọi tài liệu có con số**: báo cáo benchmark, dashboard, README khoe năng lực. Bốn mục đầu
**[BẮT BUỘC]**; ba mục sau **[OPT]** — chỉ cần khi project thật sự có vòng đo lặp lại.

1. **[BẮT BUỘC] Trung thực mẫu số.** Mọi tỉ lệ phải tự giải trình `denominator + Σ excluded == total`, và
   mọi đơn vị vào **đúng một** nhóm loại-trừ-lẫn-nhau. *Tiền lệ:* một project báo **66,4%**, sau phát hiện
   đó là tỉ lệ trên tập con (đã âm thầm loại nhóm fail) — tính trên toàn bộ ground truth: **45,0%**.
2. **[BẮT BUỘC] Chưa đo được → `None`, không bao giờ `0.0`/`1.0`.** *Tiền lệ:* 5/5 bản ghi thiếu cờ
   `edited` (tạo trước khi có trường đó) → số cũ báo "0% phải sửa tay" nghe như hoàn hảo; đúng ra là *chưa
   đo được*. Tài liệu/UI hiện `n` cạnh mọi `%`; `n < 5` thì hiện phân số thô thay vì phần trăm.
3. **[BẮT BUỘC] Nói rõ mẫu số do AI hay do người định ra.** Nếu chấm bằng LLM-as-judge thì **mẫu số do
   chính judge quyết** — câu nào judge bỏ qua sẽ biến mất khỏi cả tử lẫn mẫu, điểm tự đẹp lên mà nhìn số
   không biết. Bắt buộc kèm chỉ số coverage + version của judge (`JUDGE_PROMPT_VERSION`).
4. **[BẮT BUỘC] Negative control.** Một cổng chất lượng chỉ từng xanh mà **chưa từng đỏ** là chưa chứng
   minh nó sống. Cố tình chèn vi phạm → xác nhận đỏ đúng chỗ → hoàn nguyên. Ghi việc này vào tài liệu.
5. **[OPT] Ground truth thay cho LLM-as-judge.** Có nhãn người thì đo bằng nhãn người (chính xác hơn, đắt
   hơn, chậm hơn). Judge hợp khi cần lấy mẫu liên tục/rẻ; nhãn người hợp khi cần con số đem đi cam kết.
   Tốt nhất: judge chạy thường xuyên, **hiệu chuẩn định kỳ** bằng 30–50 mẫu nhãn người.
6. **[OPT] So sánh có kiểm định.** Trước/sau đổi prompt trên **cùng** tập dữ liệu → **McNemar's paired
   test**. Chỉ đáng làm khi thay đổi nhỏ và tập test không lớn — khi khác biệt lớn rõ ràng thì không cần.
7. **[OPT] Hard set.** Giữ riêng tập N ca FAIL **lặp lại qua ≥2 lần chạy** (khó thật, không phải nhiễu).
8. **[OPT] Root-cause trước khi chỉnh tham số.** *Tiền lệ:* trong một bài đo truy hồi, **90,5%** ca fail
   rơi vào nhóm "lấy đúng loại thông tin nhưng **sai hẳn vị trí nguồn**" — tức là lỗi *chọn nguồn*, không
   phải lỗi *ngưỡng*. Nới/siết ngưỡng bao nhiêu cũng vô nghĩa. **Phân loại lỗi trước, chỉnh tham số sau.**

---

## 6b. [OPT — nhưng mặc định BẬT nếu project có ≥2 tầng biến-đổi-dữ-liệu-bằng-AI] Minh bạch — Provenance
## — Độ tin cậy, cho pipeline AI dày đặc

*Đúc từ một lần audit thật (2026-08-12) trên một hệ 3-repo (OCR/trích xuất → hoà giải đa nguồn → đồ thị
tri thức → agent hội thoại). Mẫu n=1 hệ thống — đọc như "đây là 6 dạng lỗ hổng có thật, đã tìm và xác
nhận bằng đọc code trực tiếp", không phải quy luật phổ quát; nhưng hình dạng lỗ hổng (constant giả làm đo
thật, chuỗi provenance đứt ở ranh giới format, cơ chế chỉ tới tay vai vận hành chứ không tới tay
end-user, nhãn cô lập khỏi số cần hiệu chuẩn, audit trail một chiều) đủ tổng quát để đưa vào playbook.*

**Vì sao cần một mục riêng, tách khỏi §6:** §6 kiểm tra một con số đã tồn tại có được TRÌNH BÀY trung
thực không (mẫu số, `None` vs `0.0`, coverage). Mục này đứng TRƯỚC §6 một bước — hỏi con số đó **có thật
sự đo được cái nó tuyên bố đo** không, và nếu có, **nó có tới được người cần thấy nó** không. Một pipeline
càng nhiều tầng biến đổi (OCR → LLM trích xuất → hoà giải → UI) thì càng dễ để tầng cuối "trông chắc
chắn" trong khi không tầng nào bên dưới thật sự đo gì cả — mỗi tầng tự thấy hợp lý cục bộ, không ai audit
xuyên suốt.

**Bốn câu hỏi audit — dùng làm khung khi rà một pipeline AI, hoặc trả lời "người dùng có biết dữ liệu họ
đưa vào chuyển hoá ra sao, tin được tới đâu, cải thiện được không" của owner/PM:**

1. **Đo THẬT hay hằng số giả làm đo thật?** Với mọi trường `confidence`/`score`/`trust` trong hệ thống:
   lần theo tới nơi nó được GÁN — là kết quả một phép đo (đếm nguồn đồng thuận, so khớp ground truth,
   model tự chấm có hiệu chuẩn), hay là một hằng số cứng (`1.0`, `0.5`, mặc định)? *Anti-pattern đã gặp:*
   một bước ingest gán `confidence=1.0` cho MỌI bản ghi bất kể chất lượng nguồn; một bước khác gán `0.5`
   cứng làm "thấp hơn structured" — cả hai đều là placeholder ngụy trang thành phép đo, và mọi công thức
   hoà giải phía sau (dù bản thân công thức ĐÚNG) thừa hưởng luôn sự giả đó. Một tín hiệu đồng thuận-giữa-
   2-model (2 LLM cùng ra 1 giá trị) KHÔNG PHẢI confidence đã hiệu chuẩn — 2 model có thể cùng sai tương
   quan (cùng đọc nhầm 1 kiểu lỗi) → đồng thuận cao nhưng giá trị sai. Đặt tên khác đi (`agreement`, không
   phải `confidence`) để không ai nhầm gán nó thẳng vào trường tin cậy.
2. **Tín hiệu tin cậy có tới ĐÚNG luồng người dùng hay dùng nhiều nhất không?** Một badge/chip tin cậy tồn
   tại "ở đâu đó trong codebase" KHÔNG chứng minh người dùng thấy nó — kiểm theo **vai trò + luồng cụ
   thể**, không phải theo tính năng. *Anti-pattern đã gặp:* badge trust/confidence dựng đầy đủ cho công cụ
   vận hành (Steward/Admin), nhưng luồng chat chính mà end-user dùng nhiều nhất hoàn toàn không có — bộ
   gom nguồn phía UI chỉ nhận diện được vài khoá JSON cố định (`{label, sub, href}`-kiểu); một tool khác
   TRẢ VỀ đúng dữ liệu tin cậy cần thiết nhưng đặt tên khoá khác (`facts` thay vì `sources`) nên bộ gom
   không bao giờ nhận ra — chuỗi provenance "đủ dữ liệu" nhưng đứt đúng ở ranh giới format UI, không đứt ở
   backend. Audit bằng cách LẦN THEO một request thật từ điểm vào tới điểm hiện ra màn hình, không phải
   liệt kê tính năng đã dựng.
3. **Có ground-truth gán nhãn không, và nó hiệu chuẩn ĐÚNG con số cần hiệu chuẩn không?** "Có nhãn người"
   và "nhãn đó hiệu chuẩn được số bạn đang tin" là hai câu khẳng định khác nhau — kiểm CẢ HAI. *Anti-
   pattern đã gặp:* một pipeline trích xuất có hẳn quy trình gán nhãn người + đo precision/recall/F1 thật
   — nhưng chỉ cho lỗi trích xuất TRƯỜNG, hoàn toàn cô lập khỏi ngưỡng hoà giải đa nguồn/điểm "độ trung
   thực câu trả lời" ở tầng khác của cùng hệ thống. Có nhãn ở MỘT nơi dễ khiến người đọc báo cáo lầm tưởng
   "hệ thống này có ground truth" theo nghĩa rộng, trong khi con số đang dùng ở nơi khác chưa từng chạm
   nhãn nào.
4. **Feedback được GHI hay được ĐỌC LẠI?** Một cơ chế ghi log/audit khi người dùng phản hồi (chấp
   nhận/sửa/từ chối một đề xuất do AI tạo) là **audit trail MỘT CHIỀU** cho tới khi có thứ gì đó THẬT SỰ
   đọc lại nó để đổi hành vi (prompt, ngưỡng, tập eval, cảnh báo tỉ lệ từ chối cao). *Anti-pattern đã
   gặp:* ba đường ghi feedback riêng biệt, đủ dữ liệu, chạy ổn định nhiều tháng — grep toàn hệ thống cho
   bất kỳ job/route nào ĐỌC LẠI các bảng đó để hành động: không có. Trước khi trả lời "agent có cải thiện
   được không" bằng "có, vì chúng tôi ghi log" — hỏi tiếp: *ai đọc log đó, và làm gì khác đi sau khi đọc?*

**Khi audit xong — sản phẩm là gì:** KHÔNG code ngay. Bốn câu hỏi trên thường lộ ra quyết định owner phải
chốt hướng (đầu tư hiệu chuẩn ở đâu trước, mức độ hiện ra UI, có kích hoạt vòng cải thiện hay chưa) —
đây đúng là loại nội dung "cần trao đổi trước khi thành việc code" mà §11b nói tới; xem
**GIT-FLOW.md § mới "GitHub Discussions — trước khi thành Issue"** để biết đăng ở đâu, và **đừng** tự
quyết thay owner rồi mở PR luôn.

---

## 7. Vòng đời — ai cập nhật, lúc nào

| Sự kiện | Cập nhật gì | Ai |
|---|---|---|
| Thêm/đổi thuật ngữ | Glossary (+ID mới ở cuối dãy) **trước** khi viết tài liệu dùng nó | Người viết |
| Đảo một quyết định | ADR mới + ADR cũ → `Superseded` + link 2 chiều | Người đề xuất |
| Đóng một TODO | roadmap §TODO (trạng thái + **Verify** thật) — cùng commit với code | Người sửa |
| Đổi API/contract | Interface doc + Error Catalog + smoke tương ứng | Người sửa |
| Kết thúc phiên dài | HANDOFF (§5.5) | Agent/người |
| Phát hiện doc lệch code | Sửa ngay khi va chạm — **doc lệch code là NỢ**, không phải chuyện nhỏ | Ai va vào |

**Definition of Done** trước khi chuyển Draft → In Review:
- [ ] Không thuật ngữ nào dùng mà **chưa có trong Glossary**
- [ ] Không lý do quyết định nào **kể lại** thay vì trích dẫn ADR
- [ ] Mọi ô "—"/khoảng trống là **có chủ đích**, ghi rõ tài liệu nào sẽ điền
- [ ] Mọi tuyên bố "đã xong" có **lệnh + kết quả thật** kèm theo
- [ ] Mọi tỉ lệ có **mẫu số** đi kèm (§6.1)
- [ ] Header ghi đúng loại bump + có/không cần ADR (§L4)
- [ ] Link nội bộ không gãy; sơ đồ Mermaid render được

★ **Tự-review trước khi merge bắt được lỗi thật** — kể cả lỗi tự mâu thuẫn trong chính header (tự khai
"loại 2 ⇒ MINOR" rồi lại ghi "bump PATCH"). Đọc lại bản mình vừa viết như đọc bản của người khác.

---

## 8. Ép bằng máy — biến luật thành check

Gom vào một lệnh duy nhất để không ai quên:

```makefile
check: lint typecheck importcheck doccheck test
importcheck: ; lint-imports              # import-linter: ranh giới kiến trúc
doccheck:    ; markdownlint docs/ && python scripts/check_doc_ids.py
```

- **`import-linter`** — ranh giới kiến trúc thành ràng buộc kiểm được. Phân tích **tĩnh** (đọc AST, không
  chạy code) ⇒ chạy được cả ở nơi cấm chạy code. Ba bẫy đã dính, ghi lại để khỏi mất thời gian:
  1. **Xanh vì MÙ:** thư mục thiếu `__init__.py` là *namespace package* → công cụ **bỏ qua sạch** module
     bên trong (thực tế: chỉ thấy 84/125 tệp, toàn bộ lớp API vô hình). Đếm số tệp được phân tích, đối
     chiếu số tệp thật.
  2. Contract `forbidden` tính **cả chuỗi gián tiếp** → cấm cả package rồi miễn trừ lung tung sẽ đỏ oan;
     việc phân **thứ bậc** phải dùng contract `layers`.
  3. **Kiểm chứng ngược** bắt buộc (§6.4).
- **`check_doc_ids.py`** (tự viết, ~50 dòng) — mọi `GLOSS-…`/`ADR-…` được trích dẫn phải tồn tại; không
  ID trùng; không ID bị renumber.
- **`markdownlint` + `vale`** — hình thức và giọng văn.

**Chỉ khai ràng buộc ĐANG ĐÚNG THẬT** (kiểm trước khi viết). Contract đỏ-sẵn = tiếng ồn → người ta tắt đi
→ mất luôn tác dụng.

---

## 9. Bảng tra: triệu chứng → luật nào chặn

| Triệu chứng đã gặp thật | Luật |
|---|---|
| "Cái này gọi là gì nhỉ?" — 3 tên cho 1 khái niệm | L1 Glossary |
| "Sao hồi đó chọn Temporal?" — không ai nhớ | L1 ADR |
| Sửa một chỗ, hai chỗ khác thành sai | L2 SSOT |
| Trích dẫn gãy sau khi "dọn dẹp cho gọn" | L3 ID bất biến |
| Quyết định bị đảo lặng lẽ trong một PR chức năng | L4 |
| "Chắc chạy được" → hoá ra route chưa hề tồn tại, scrape 404 nhiều tuần | L5 |
| Phiên sau tin file trạng thái cũ rồi làm lại việc đã xong | L6 |
| Bất biến kiến trúc bị phá dần dù tài liệu ghi rõ | L7 + §8 |
| Số đẹp mà sai (66,4% → 45,0%) | §6.1–6.2 |
| Tinh chỉnh ngưỡng mãi không cải thiện | §6.5 |

---

## 10. Sprint 0 cho project mới — checklist một ngày

1. **Chọn mức** S/M/L (§2), ghi thẳng vào `docs/README.md`: *"Bộ tài liệu này ở mức S. Lên M khi
   \<trigger\>."*
2. **Đọc TOÀN VĂN** mọi bản nháp/khảo sát đang có. Không viết Glossary từ trí nhớ.
3. **Glossary** — hợp nhất mỗi khái niệm về một tên, cấp ID, đánh dấu 🔒/🟡, ghi mục "nhập nhằng đã giải
   quyết" và "thuật ngữ CỐ Ý chưa đưa vào (kèm trigger)".
4. **3–5 ADR nền tảng** — đóng khung phần lý luận đã có sẵn trong bản nháp, đủ 4 mục Nygard.
5. **Context Map** — Bounded Context + quan hệ, trích dẫn ADR ở bước 4.
6. **`docs/README.md`** — bản đồ đọc + nguyên tắc bất biến + trỏ `HANDOFF.md`.
7. **`AGENT.md`/`AGENTS.md`** — ranh giới hành động, kỷ luật hạ tầng, nơi ghi issue, quy tắc commit/push.
   **Tách khỏi file này.**
8. **`make check`** — dựng khung ngay cả khi mới có 1–2 check; thêm dần (§8).
9. Từ đây trở đi: mỗi thay đổi code chạm kiến trúc/hành vi → **cùng commit** cập nhật tài liệu tương ứng.
   Doc đi sau code một nhịp là còn cứu được; đi sau mười nhịp là viết lại.

---

## 11. Các TUỲ CHỌN [OPT] — chọn theo project, ghi lại đã chọn gì

Những thứ dưới đây **không có đáp án đúng phổ quát**. Chọn xong ghi một dòng ở `docs/README.md`
(*"Bộ này dùng: ADR gộp một file · docs trong repo · Nygard · ngôn ngữ Việt"*), để phiên sau/người sau
không tự đổi kiểu giữa chừng — **nhất quán quan trọng hơn phương án**.

| # | Điểm chọn | Phương án | Chọn A khi | Chọn B khi |
|---|---|---|---|---|
| O1 | **Nơi để tài liệu** | A: trong repo (`docs/`) · B: wiki/Notion/Confluence | Tài liệu đổi cùng nhịp code, muốn review chung PR, muốn CI check | Người đọc chính là phi kỹ thuật, cần bình luận/nhúng phong phú |
| O2 | **Cấu trúc ADR** | A: gộp một `adr-log.md` · B: mỗi ADR một file `adr/0007-*.md` | < ~15 ADR, muốn đọc liền mạch | Nhiều ADR, nhiều người **hoặc nhiều agent** viết song song (tránh xung đột merge) |
| O3 | **Định dạng ADR** | A: **Nygard** (Context/Decision/Consequences) · B: **MADR** (thêm bảng tiêu chí + "Considered Options") | Quyết định mang tính định hướng, lý do quan trọng hơn so sánh | Quyết định chọn-công-cụ, cần so sánh nhiều phương án theo tiêu chí |
| O4 | **Đánh số tài liệu** | A: số theo tầng (`01-…`, `20-…`) · B: tên ngữ nghĩa (`algorithm.md`) | Bộ lớn, cần thứ tự đọc rõ ràng | Bộ nhỏ, tên tự nói lên nội dung, tránh việc "chèn số" khó xử |
| O5 | **Version tài liệu** | A: **semver** trong header + lịch sử bump · B: chỉ dựa vào `git log` | Có người ngoài đọc/duyệt, cần trạng thái Approved | Một người, đọc `git log` là đủ, muốn tránh chi phí bump |
| O6 | **Traceability Matrix** | A: có bảng riêng (yêu cầu ↔ thiết kế ↔ test) · B: link tại chỗ | Có audit/nghiệm thu, hoặc >30 yêu cầu | Bộ nhỏ — bảng riêng sẽ lệch nhanh hơn nó giúp |
| O7 | **Quy trình duyệt** | A: Discussion → Issue → PR/MR → merge=Approved (xem §11b) · B: sửa thẳng, ADR khi đảo quyết định | Nhiều người, cần dấu vết thảo luận · **HOẶC nhiều AGENT chạy song song trên cùng repo (dù chỉ 1 người vận hành)** — Issue = đơn vị việc cô lập, PR = đơn vị review cô lập, tránh N agent cùng sửa một file TODO văn bản (xung đột merge liên tục, không ai biết agent nào đang làm gì) | Một người, **một agent tại một thời điểm**, tốc độ cao (áp A lúc này mới là tự trói) |
| O8 | **Tài liệu người dùng** | A: theo **Diátaxis** (tutorial/how-to/reference/explanation) · B: một `huong-dan-su-dung.md` | Có người dùng ngoài thật sự | Còn PoC/nội bộ |
| O9 | **Ngôn ngữ** | A: tiếng Việt · B: tiếng Anh · C: lai (thuật ngữ giữ nguyên tiếng Anh) | Người đọc là team Việt | Có cộng tác viên ngoài / định mở nguồn |
| O10 | **Sơ đồ** | A: Mermaid trong markdown · B: drawio/Excalidraw xuất PNG | Muốn diff được, sửa được bằng agent | Sơ đồ trình bày, nhiều bố cục thủ công |
| O11 | **File trạng thái phiên** | A: có `HANDOFF.md` · B: không, dựa vào issue tracker | Làm việc cùng agent, hay bị nén ngữ cảnh | Có tracker kỷ luật tốt và luôn cập nhật |

**Khuyến nghị mặc định cho project kiểu "một người + MỘT agent AI tại một thời điểm, tốc độ cao, người
dùng nội bộ"**: O1-A · O2-A · O3-A · O4-B · O5-B · O6-B · O7-B · O8-B · O9-A · O10-A · O11-A. Lên mức M/L
thì đảo dần sang A ở O5/O6/O7 — và khi đổi, **ghi lý do đổi như một ADR** (chính bộ tài liệu cũng là một
hệ thống có quyết định kiến trúc).

**O2 và O7 có một trigger đảo chung, độc lập với quy mô S/M/L:** quy mô S/M/L (§2) đo theo số người;
điều kiện đảo O2/O7 đo theo **số agent chạy đồng thời trên cùng repo**. Hai trục độc lập — một project
quy mô S (1 người) với ≥2 agent chạy song song đã đủ điều kiện đảo O2-B/O7-A, không cần chờ lên M/L.
Cơ chế: nhiều agent cùng ghi vào một file đang tăng dần (`adr-log.md`, `roadmap.md §TODO`) tạo xung đột
merge; Issue/PR/ADR-theo-file cô lập việc theo agent. Đảo tại đây là Loại 2 theo L4 (bổ sung/làm rõ một
nhánh đã có sẵn trong bảng, không đảo ngược quyết định nào) ⇒ không cần ADR-của-lựa-chọn, chỉ cần ghi lại
ở `docs/README.md`. Quy trình đảo khi project đã có nội dung O7-B từ trước (roadmap §TODO đang chứa việc
thật): `GIT-FLOW.md` §11b "Kích hoạt O7-A giữa chừng".

---

## 11b. [OPT] Git làm hệ quản lý tài liệu & công việc — tách ra file riêng

Phương án O7-A đầy đủ: **Issue = kho TODO · MR/PR = đơn vị review · merge = chấp nhận · CI = cổng máy.**
Nội dung chi tiết (constitution.md · quy ước nhánh `agent/*` · run record · tách SPEC/PLAN · hệ sinh
thái nhiều repo) đã chuyển sang **`GIT-FLOW.md`**, cạnh file này — lý do: đây là phần **[OPT]** dài nhất
trong toàn bộ playbook, và chỉ project **đã chọn O7-A** mới cần agent tải nó mỗi phiên. Đúng L2 của
chính file này (một sự thật, một nơi, nơi khác chỉ LINK): nếu bạn không dùng O7-A, đừng nạp thêm ~400
dòng vào context của agent để làm gì.

**Đọc `GIT-FLOW.md` khi nào:** đã chọn O7-A ở bảng §11 trên, hoặc đang cân nhắc chuyển sang mô hình đó.
**Không cần đọc:** vẫn dùng phương án O7-B (sửa thẳng, ADR khi đảo quyết định) — quy trình đủ nhẹ để
không cần bàn tới git-as-task-tracker.

---

## 12. Ba thứ KHÔNG nên làm

1. **Đừng chép quy trình nặng xuống quy mô nhỏ.** Discussion→Issue→ADR→PR + "Approved bất biến tuyệt
   đối" hợp với team nhiều người; một người + tốc độ cao mà áp nguyên là tự trói.
2. **Đừng viết tài liệu mô tả lại code.** Tài liệu trả lời **VÌ SAO** và **BẤT BIẾN NÀO**; cấu trúc code
   đọc từ code. Cái gì `git log` đã ghi thì đừng chép lại.
3. **Đừng để tài liệu tự khen.** Câu "hệ thống đảm bảo độ chính xác cao" không có mẫu số thì không phải
   thông tin. Thay bằng: đo cái gì, trên bao nhiêu mẫu, ngày nào, bằng lệnh nào.
