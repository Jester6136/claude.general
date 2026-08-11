# AGENT.md — Quy tắc vận hành cho agent (playbook mang đi được, companion của CLAUDE.md)

> **File này là gì:** quy tắc **vận hành** agent — ranh giới hành động, kỷ luật hạ tầng, nơi ghi issue,
> commit/push, và **cách tự-kiểm trước khi báo "xong"**. Chép nguyên file này sang repo mới cạnh
> `CLAUDE.md`, điền các chỗ `<...>`, xoá phần không áp dụng (đánh dấu `[OPT]`).
> **File này KHÔNG phải:** phương pháp luận viết tài liệu (Glossary/ADR/quy mô S-M-L) — thứ đó thuộc
> `CLAUDE.md` cạnh nó. Hai file, hai việc, đừng trộn.
>
> **Bootstrap bắt buộc:** `CLAUDE.md` (auto-load mỗi phiên bởi Claude Code) phải có một dòng ở đầu nói
> *"nếu có `AGENT.md` ở gốc repo, đọc nó trước khi code"* — thiếu dòng đó thì file này chỉ có tác dụng
> khi ai đó nhớ nhắc, không tự động xảy ra mỗi phiên. Xem `CLAUDE.md` §0.5.

**Mục lục:** §1 ranh giới hành động · §2 trước khi đổi hạ tầng/bảo mật · §3 ghi issue — một nguồn sự
thật · §4 test — CI tự kiểm vs cần hạ tầng sống · §5 commit/push · **§6 bằng chứng trước khi tuyên bố
(tự-review bắt buộc)** · §7 vòng lặp Issue→PR (chi tiết ở `GIT-FLOW.md`, chỉ đọc khi đã chọn O7-A).

---

## 1. Ranh giới KHÔNG được tự ý vượt qua

Điền cụ thể cho project của bạn — đây là khuôn, không phải luật chung chung:

- ★**KHÔNG sửa cấu hình phục vụ/hạ tầng lõi** (nêu cụ thể: `<vd: model serving, timeout, rate-limit,
  routing>`) trừ khi chủ tường minh yêu cầu. Nghi hiệu năng/hành vi KHÔNG phải giấy phép tự sửa — báo
  cáo phát hiện + đề xuất, chờ quyết định, KHÔNG tự thi hành.
- **KHÔNG kết luận "hỏng/treo/lỗi" từ một mẫu đơn hoặc thiếu kiên nhẫn.** Đo lại đúng kịch bản gốc, đủ
  lâu, trước khi báo cáo là sự cố. Đừng bắn thử-nghiệm phụ chạm hạ tầng dùng-chung để "cô lập nghi vấn"
  khi một phép đo kiên nhẫn hơn là đủ.
- **KHÔNG lưu secret ra ngoài phạm vi project** mà không xin phép rõ ràng (vd `~/.git-credentials` toàn
  hệ, ngoài thư mục repo). Sandbox chặn ghi-ngoài-project là tín hiệu ĐÚNG — không tìm cách lách, dừng
  lại và giải thích, để chủ tự làm hoặc tự quyết cho phép.
- **KHÔNG push khi chưa được yêu cầu/ngữ cảnh chưa rõ** — commit local trước; hỏi hoặc chờ xác nhận
  trước khi đẩy lên remote dùng chung. Token do user đưa trong chat → dùng **one-off qua URL**
  (`git push https://oauth2:<token>@host/...`), không tự ý ghi vào credential store toàn hệ.

## 2. Trước khi đổi bất kỳ cấu hình hạ tầng/bảo mật nào

1. **So sánh code đang chạy với repo HEAD trước khi bật/tắt bất kỳ cổng bảo mật nào:**
   ```
   git -C <repo> log -1 --format='%h %cI %s'
   docker inspect <image>:latest --format '{{.Created}}'   # ⚠ image, KHÔNG phải container (.Created của
                                                             #   container chỉ là lúc restart, có thể tái dùng
                                                             #   image cũ — bẫy thật đã gặp ở project nguồn)
   ```
   Lệch → **rebuild trước**, đừng suy luận "chắc là được".
2. Rebuild → restart → **verify từng bước bằng lệnh thật** (curl matrix, preflight, smoke).
3. Sau khi đổi xong: chạy lại preflight/smoke **mọi phía chạm nhau**. Coi preflight FAIL sau thay đổi là
   nghiêm trọng dù chức năng chính vẫn chạy được — preflight tự nó có thể có bug sót.

## 3. Ghi Issue / Feature / Task — MỘT nguồn sự thật, không phân mảnh

Chọn MỘT trong hai theo O7 (`CLAUDE.md` §11), ghi rõ đã chọn cái nào. **Phép thử để chọn không phải "có
mấy người" mà là "có mấy AGENT chạy ĐỒNG THỜI trên repo này":**

- **O7-B (mặc định khi CHỈ MỘT agent tại một thời điểm):** mọi vòng "raise issue → fix → verify" ghi vào
  `<roadmap>.md §TODO` (mục có sẵn khớp chủ đề, hoặc thêm mục mới cùng khuôn ở `CLAUDE.md` §5.4). Trạng
  thái: `⬜` chưa làm · `🔨` code xong chưa verify · `✅` code+verify · `★` bài học đáng nhớ. **Không tạo
  file log rời** (`ISSUES.md`/`CHANGELOG.md`) — phân mảnh tri thức là cách mất nó.
- **O7-A (git-as-management, xem `GIT-FLOW.md`) — bắt buộc cân nhắc ngay khi có ≥2 agent chạy song song,
  kể cả nếu chỉ có 1 người vận hành cả hai:** GitHub/GitLab Issue là nguồn sự thật cho việc đang mở, mỗi
  agent một Issue + một worktree/branch (`agent/<issue-id>-<slug>`) + một PR. Lý do KHÔNG phải "cần dấu
  vết thảo luận" — mà là N agent cùng sửa một file `§TODO` văn bản sẽ xung đột merge liên tục và không
  agent nào biết agent khác đang làm gì; Issue/PR cô lập việc theo agent, đúng thứ nó sinh ra để làm
  (xem `CLAUDE.md` §11 O7, mục "★ O7 có trigger đảo riêng"). `§TODO` (nếu còn tồn tại song song trong
  lúc chuyển đổi) chỉ là nguồn phụ tạm thời — nói rõ trong README.md dự án đang ở giai đoạn nào của quá
  trình chuyển, đừng để cả hai cùng là "nguồn chính".

Đổi TODO/Issue **CÙNG COMMIT** với code fix — doc lệch code = nợ kỹ thuật, coi như việc chưa xong.

## 4. Test — CI tự kiểm được vs cần GPU/hạ tầng sống

Bất kỳ project nào có ≥1 test đụng model/DB-sống/GPU sẽ cần ranh giới này sớm hay muộn — đặt tên tường
minh ngay từ Sprint 0 rẻ hơn nhiều so với để CI tự khám phá qua timeout.

| Tầng | Gồm gì | Chạy ở đâu | Cơ chế phân biệt (MÁY, không phải quy ước bằng lời) |
|---|---|---|---|
| **A — CI tự kiểm được** | static (cú pháp/boundary/lint nhóm bắt lỗi thật) · smoke THUẦN (không chạm DB/mạng/GPU) · test plumbing/logic thuần | `./scripts/check.sh --all` — chạy được trên runner hosted: không GPU, không service sống, chỉ cần cài dependency | Marker/naming quy ước rõ ràng — vd docstring `PURE smoke`, hoặc tên file `test_*` cho unit thuần |
| **B — cần GPU/hạ tầng sống** | LLM/model thật, DB thật, service phụ thuộc thật | **CHỈ** máy dev/máy hạ tầng thật, thủ công hoặc lịch riêng — **KHÔNG BAO GIỜ** trong CI hosted | KHÔNG mang marker tầng A; đặt tên khác hẳn (`eval_*`, `*_e2e`, `smoke_*_e2e`) để "cố ý loại trừ" không lẫn "quên" |

Liệt kê CỤ THỂ tầng B theo module ngay khi phát hiện (đừng để "ngầm hiểu") — bảng trống dưới đây điền
dần:

| Module tầng B | Cần gì mới chạy được |
|---|---|
| `<điền khi phát hiện>` | `<LLM thật / DB sống / GPU>` |

★ Workflow CI **CHỈ được phép** gọi `./scripts/check.sh --all` (= tầng A nguyên vẹn). Không job nào gọi
trực tiếp file tầng B. Thêm module tầng A mới thì tự động được gom vào (marker/naming, không sửa
workflow); thêm module tầng B thì **đừng gắn marker tầng A** — gắn nhầm là cách nhanh nhất khiến CI đỏ
oan vì thiếu hạ tầng, tưởng nhầm là lỗi code.

★ **Bài học đáng nhớ (nguồn: dự án quan sát được):** test không ai chạy tự động sẽ **thối lặng lẽ** —
code đổi có chủ đích, test không cập nhật theo, rồi im lặng đỏ hàng tháng không ai biết vì không ai
chạy nó. Không phải "test tệ", mà là "test không nằm trong vòng lặp nào cả". Gắn vào `check.sh`/CI ngay
khi viết test đầu tiên, đừng để dồn.

## 5. Commit / Push

- Message: dòng đầu `type(scope): tóm tắt` (đọc `git log -5` để khớp giọng/quy ước đã dùng trong repo
  trước khi viết commit đầu tiên của session) + thân giải thích gốc-rễ/fix/verify.
- Set `git config user.name/user.email` khớp tác giả đã dùng trong repo (`git log -1 --format='%an <%ae>'`)
  nếu identity local chưa cấu hình — đừng bịa danh tính khác.
- **Push khi:** user yêu cầu rõ, hoặc đang nối tiếp trực tiếp một chu trình mà user vừa tự chuẩn bị
  credential cho việc đó — vẫn nói rõ mình sắp/đã push, không âm thầm.

## 6. Bằng chứng trước khi tuyên bố — tự-review BẮT BUỘC trước khi báo "xong"

> **Nguồn:** rút từ va chạm thật trong một phiên làm việc — agent viết một bảng markdown có `|` trần
> trong ô (vỡ table khi render) và viết "xem §TODO" trỏ tới một mục **chưa hề tồn tại** — cả hai đều là
> tuyên bố sai mà chính agent không phát hiện ra cho tới khi được hỏi thẳng "có vấn đề gì không?". Đây
> là dạng cụ thể của L5 (`CLAUDE.md`) mà đáng được tách ra như một BƯỚC, không chỉ một nguyên tắc.

Trước khi nói một việc **đã xong** (đóng TODO, đóng Issue, báo cáo kết quả), tự chạy checklist này —
đừng tin trí nhớ trong hội thoại, **grep/chạy lại thật**:

- [ ] Mọi `§TODO`/ID (`GLOSS-*`, `ADR-*`, số Issue) vừa trích dẫn — **grep để xác nhận nó thật sự tồn
      tại** ở đúng chỗ đã trỏ tới, không phải "chắc là có ghi ở đâu đó".
- [ ] Mọi bảng markdown vừa viết — quét `|` trần bên trong code-span/nội dung ô (vỡ table khi render);
      không tự tin "chắc markdown parser hiểu được".
- [ ] Mọi lệnh **Verify** ghi trong doc — **đã thực sự chạy trong phiên này**, không phải nhớ lại/suy ra
      từ một lần chạy trước đó có thể đã cũ.
- [ ] Mọi con số/tỉ lệ — có mẫu số đi kèm (`CLAUDE.md` §6.1); chưa đo được ghi `None`, không phải `0`.
- [ ] Nếu vừa sửa code dựa trên "hợp đồng cũ lệch hợp đồng mới" — đã **đọc source thật** của hàm/field
      đó để xác nhận hợp đồng mới, không đoán từ tên biến hay từ thông báo lỗi một mình.

Việc này **không thay thế** review của người — nó là NGƯỠNG TỐI THIỂU trước khi đưa việc gì đó cho người
đọc coi là đáng tin. Bỏ bước này không tiết kiệm được thời gian thật, vì người đọc sẽ phải tự phát hiện
lại đúng những lỗi bước này bắt được.

## 7. Vòng lặp làm việc: Issue → worktree → implement → cổng → PR → review → merge [OPT — chỉ khi chọn O7-A]

Chi tiết đầy đủ (constitution.md · quy ước nhánh `agent/*` · run record · SPEC/PLAN · hệ sinh thái nhiều
repo) ở **`GIT-FLOW.md`** — không lặp lại ở đây (L2 SSOT). Tóm tắt vòng lặp mỗi việc:

1. `git worktree add .worktrees/<slug> -b <prefix>/<issue-id>-<slug> origin/<nhánh-nền>`.
2. Overlap scan 2 phút (đã có ai làm việc này chưa) trước khi code.
3. Implement trong ranh giới Issue/SPEC. **Gặp chỗ MƠ HỒ → DỪNG, hỏi ở Issue, KHÔNG tự suy diễn.**
4. `./scripts/check.sh --all` — ĐỎ thì tự sửa, đừng mở PR.
5. Chạy §6 (checklist bằng chứng) trước khi mở PR.
6. Mở PR, `Closes #NN`, một commit gói trọn một việc.
7. Sau merge: cập nhật `HANDOFF.md` + đóng Issue + dọn worktree, cùng commit với code.

Nếu chưa chọn O7-A (đang dùng O7-B — sửa thẳng, ADR khi đảo quyết định): bỏ qua §7, dùng §3 (roadmap
§TODO) làm nguồn việc-đang-mở.
