# AGENT.md — Quy tắc vận hành cho agent (playbook mang đi được, companion của CLAUDE.md)

> **File này là gì:** quy tắc **vận hành** agent — ranh giới hành động, kỷ luật hạ tầng, nơi ghi issue,
> commit/push, và **cách tự-kiểm trước khi báo "xong"**. Chép nguyên file này sang repo mới cạnh
> `CLAUDE.md`, điền các chỗ `<...>`, xoá phần không áp dụng (đánh dấu `[OPT]`).
> **File này KHÔNG phải:** phương pháp luận viết tài liệu (Glossary/ADR/quy mô S-M-L) — thứ đó thuộc
> `CLAUDE.md` cạnh nó. Hai file, hai việc, đừng trộn. File này chỉ tự có hiệu lực mỗi phiên nhờ dòng
> bootstrap ở `CLAUDE.md` §0.5.

**Mục lục:** §1 ranh giới hành động · §2 trước khi đổi hạ tầng/bảo mật · §3 ghi issue — một nguồn sự
thật · **§4 test & NGHIỆM THU TẤT ĐỊNH (N0/N1/N2 · UI qua Playwright)** · §5 commit/push · **§6 bằng chứng trước khi tuyên
bố (tự-review bắt buộc)** · §7 vòng lặp Issue→PR (chi tiết ở `GIT-FLOW.md`, chỉ đọc khi đã chọn O7-A) ·
**§8 research web (học thuật + industry) — TỰ ĐỘNG trước khi chốt phương án/root-cause khó** · **§9 đặt
tên trong code/file LUÔN tiếng Anh**.

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

Chọn MỘT trong hai theo O7 — điều kiện chọn (số AGENT chạy đồng thời, không phải số người) ở `CLAUDE.md`
§11, ngay dưới bảng O. Ghi rõ trong `docs/README.md` đã chọn cái nào.

- **O7-B:** mọi vòng "raise issue → fix → verify" ghi vào `<roadmap>.md §TODO` (khuôn `CLAUDE.md` §5.4,
  trạng thái ⬜/🔨/✅ theo L5). Không tạo file log rời (`ISSUES.md`/`CHANGELOG.md`).
- **O7-A:** GitHub Issue là nguồn việc-đang-mở; quy trình ở `GIT-FLOW.md` (kể cả cách chuyển từ
  O7-B giữa chừng).

Đổi TODO/Issue **CÙNG COMMIT** với code fix — doc lệch code = nợ kỹ thuật, coi như việc chưa xong.

## 4. Test & NGHIỆM THU TẤT ĐỊNH — chạy ở MÁY (local-first) · tầng A vs cần GPU/hạ tầng sống

### 4.1 Nguyên tắc gốc: tất định nằm ở BỘ CHẤM + DỮ LIỆU ĐÓNG BĂNG, không nằm ở thứ được chấm

**Đơn vị nghiệm thu** = một lệnh chạy được, trả **phán quyết ĐẠT/KHÔNG ĐẠT**, sao cho **cùng commit + cùng
dữ liệu đã đóng băng ⇒ cùng phán quyết**, ai chạy, chạy lúc nào cũng vậy. Mỗi việc (Issue/§TODO) có ≥1
đơn vị nghiệm thu, **khai TRƯỚC khi code** (kể cả ngưỡng), và **đã từng ĐỎ** trên nhánh nền trước khi fix
(negative control, `CLAUDE.md` §6.4) — đơn vị chưa từng đỏ chưa chứng minh nó đo được thay đổi.

Thứ KHÔNG BAO GIỜ được làm phán quyết nghiệm thu, vì chạy lại có thể ra kết luận khác:
- output sống của LLM/model (không tất định dù `temperature=0` — đổi phiên bản phía nhà cung cấp, đổi
  batching, đổi phần cứng đều làm lệch);
- LLM-as-judge chạy sống (mẫu số do chính judge quyết — `CLAUDE.md` §6.3);
- reviewer bằng LLM (skill `/code-review`) — nó **sinh finding**, không **ra phán quyết** (xem `GIT-FLOW.md`
  § "Năm cổng", G4);
- agent tự lái trình duyệt qua **Playwright MCP** để "check giao diện" — cũng là LLM điều khiển, cũng chỉ
  **sinh finding** (§4.4);
- "nhìn output thấy ổn" của người — đó là review, không phải nghiệm thu.

**Ba cấp nghiệm thu** — phân theo vị trí của thứ không tất định, không theo độ quan trọng:

| Cấp | Nghiệm thu cái gì | Cách làm cho tất định | Chạy ở đâu |
|---|---|---|---|
| **N0 — Core/platform** | Logic, bất biến, hợp đồng của lõi | Thành phần không tất định (LLM, mạng, đồng hồ, random) thay bằng **fake/stub** do core định nghĩa; assert chính xác (giá trị, schema, property-based với seed cố định) | Tầng A — CI chặn |
| **N1 — Phần mở rộng/domain** (adapter model mới, plugin domain, nhánh nghiệp vụ) | Phần mở rộng cắm **đúng hợp đồng** của core | **Bộ contract test do CORE cung cấp** — mọi adapter chạy CÙNG một bộ, adapter không tự viết tiêu chí cho chính nó. Lời gọi model thật được **ghi lại một lần (record) thành cassette**, CI chỉ **replay** | Tầng A — CI chặn (replay không cần hạ tầng sống) |
| **N2 — Chất lượng output không tất định** (model/prompt/domain có ĐỦ TỐT không) | Hành vi thật của thứ không tất định | (1) **Golden set đóng băng**, có version · (2) pin model + version + prompt-version + tham số · (3) chạy sống MỘT lần ⇒ **snapshot output có hash** · (4) **bộ chấm tất định** (exact/schema/regex/sai số số học) trên snapshot so với **ngưỡng đã khai trong Issue trước khi chạy** · (5) báo cáo theo `CLAUDE.md` §6 (mẫu số, `None`, `n`) | Sinh snapshot: tầng B. **Chấm lại snapshot: tầng A — CI chặn** |

Luật riêng của N2 (thiếu một cái là phán quyết hết tất định):
- **Sinh lại snapshot = một LẦN NGHIỆM THU MỚI**, không phải "chạy lại cho xanh". Mọi lần sinh cho cùng
  một Issue đều ghi vào PR (hash + phán quyết) — chọn lần đẹp nhất trong N lần chạy là gian lận mẫu số.
- Cần LLM-as-judge thì **output của judge cũng là một phần snapshot** (đóng băng, pin version, kèm
  coverage `CLAUDE.md` §6.3); phán quyết tính tất định từ đó. Ưu tiên bộ chấm không-LLM khi làm được.
- Ngưỡng khai trước, không chỉnh sau khi thấy số. Đổi ngưỡng = sửa SPEC của Issue, ghi lý do.
- Snapshot nhỏ → commit vào repo (`acceptance/snapshots/`); lớn → kho artifact, repo giữ hash + đường dẫn.

**Core vs phần mở rộng — ví dụ chuẩn:** thêm một model LLM để xử lý kết quả agent. KHÔNG nghiệm thu bằng
"chạy thử thấy model trả lời ổn". Làm đúng thứ tự: (1) core định nghĩa interface + fake + bộ contract
test + bộ chấm → nghiệm thu **N0**; (2) model mới là một adapter → qua bộ contract của core bằng replay
(**N1**); (3) chất lượng của nó → golden set + snapshot + ngưỡng khai trước (**N2**). Output model dao động
giữa các lần chạy KHÔNG làm phán quyết dao động theo — phán quyết chỉ đọc snapshot đã đóng băng.

**Flaky = loại khỏi cổng ngay.** Một đơn vị cho kết quả khác nhau trên CÙNG commit không phải đơn vị
nghiệm thu: cách ly (quarantine) + mở Issue sửa, KHÔNG retry-cho-tới-khi-xanh. `check.sh --acceptance`
chạy mỗi đơn vị 2 lần và đỏ nếu PHÁN QUYẾT lệch (§4.2) — chỉ bắt được lệch thô, KHÔNG chứng minh tất
định. Tất định phải đến từ thiết kế (fake, replay, snapshot, seed cố định), không từ việc chạy lại.

### 4.2 Hiện thực bằng máy

Mỗi đơn vị nghiệm thu là một file chạy được `acceptance/<issue-id>-<slug>.sh` (exit 0 = ĐẠT; exit 77 =
không chạy được, **tính là ĐỎ**; khác = KHÔNG ĐẠT). `./scripts/check.sh --acceptance` chạy tất cả, mỗi cái
2 lần. Thư mục chưa có đơn vị nào = SKIP (cảnh báo, chưa đỏ — repo mới chưa nghiệm thu gì là hợp lệ).
**Ép bằng máy:** `check.sh` lấy số Issue từ `Closes/Fixes/Resolves[:] #N` trong mô tả PR (`PR_BODY` —
`post-merge.sh` tự truyền khi chạy lại trên commit merge) hoặc, khi không có `PR_BODY`, từ tên nhánh
`agent/<N>-*` → thiếu `acceptance/<N>-*.sh` = ĐỎ. **Local-first:** GitHub giới hạn Actions nên phán quyết
KHÔNG dựa vào CI — chạy ở máy (trước PR · hook `pre-push` · `post-merge.sh` trên commit merge); CI là [OPT]. **Không** bắt được: đóng
qua URL đầy đủ, qua sidebar "Development", qua từ khoá trong commit message — dùng `Closes #N` trong mô tả
PR. Ở O7-B (không PR, không nhánh `agent/*`), luật này chỉ là kỷ luật — tự kiểm ở §6.

### 4.3 Tầng chạy: A (máy trống) vs B (hạ tầng sống)

Bất kỳ project nào có ≥1 test đụng model/DB-sống/GPU sẽ cần ranh giới này sớm hay muộn — đặt tên tường
minh ngay từ Sprint 0 rẻ hơn nhiều so với để hook/CI tự khám phá qua timeout.

| Tầng | Gồm gì | Chạy ở đâu | Cơ chế phân biệt (MÁY, không phải quy ước bằng lời) |
|---|---|---|---|
| **A — chạy được trên máy trống** | static (cú pháp/boundary/lint nhóm bắt lỗi thật) · smoke THUẦN · test plumbing/logic thuần · **N0 · N1 (replay) · chấm lại snapshot N2** | `./scripts/check.sh --all` + `--acceptance` ở máy agent/dev, hook `pre-push`, `post-merge.sh` (worktree tạm), và CI [OPT] — không GPU, không service sống | Marker/naming quy ước rõ ràng — vd docstring `PURE smoke`, `test_*`, `acceptance/*.sh` |
| **B — cần GPU/hạ tầng sống** | **sinh** snapshot N2 · **record** cassette N1 · e2e với DB/service thật | **CHỈ** máy dev/máy hạ tầng thật, chạy CÓ CHỦ ĐÍCH — **KHÔNG BAO GIỜ** trong `--acceptance`/hook/CI. Sản phẩm của tầng B (snapshot/cassette) được commit/lưu để tầng A chấm lại | KHÔNG mang marker tầng A; đặt tên khác hẳn (`eval_*`, `record_*`, `*_e2e`) |

Liệt kê CỤ THỂ tầng B theo module ngay khi phát hiện (đừng để "ngầm hiểu") — bảng trống dưới đây điền
dần:

| Module tầng B | Cần gì mới chạy được |
|---|---|
| `<điền khi phát hiện>` | `<LLM thật / DB sống / GPU>` |

★ Hook, `post-merge.sh` và workflow CI [OPT] **CHỈ được phép** gọi `./scripts/check.sh` (`--all` và
`--acceptance` = tầng A nguyên vẹn). Không nơi nào gọi trực tiếp file tầng B. Thêm module tầng A mới thì tự động được gom vào (marker/naming, không sửa
workflow); thêm module tầng B thì **đừng gắn marker tầng A** — gắn nhầm là cách nhanh nhất khiến cổng đỏ
oan vì thiếu hạ tầng, tưởng nhầm là lỗi code.

★ **Bài học đáng nhớ (nguồn: dự án quan sát được):** test không ai chạy tự động sẽ **thối lặng lẽ** —
code đổi có chủ đích, test không cập nhật theo, rồi im lặng đỏ hàng tháng không ai biết vì không ai
chạy nó. Không phải "test tệ", mà là "test không nằm trong vòng lặp nào cả". Gắn vào `check.sh` (và hook `pre-push`) ngay
khi viết test đầu tiên, đừng để dồn.

### 4.4 Giao diện — Playwright MCP để NHÌN, Playwright test để PHÁN QUYẾT

Project có giao diện thì dựng Playwright MCP **ghim phiên bản** (cách dựng + vì sao ghim: GIT-FLOW.md §
"Bộ công cụ agent khi dựng O7-A" — đọc riêng mục đó, kể cả khi dùng O7-B). Agent dùng nó để **xem** UI và **sinh finding**, như `/code-review`. Mỗi finding
về giao diện → một test Playwright dạng script (cùng `playwright-core` đã khoá, viewport cố định, tắt
animation, dữ liệu/đồng hồ cố định, backend fake/replay) đặt trong đơn vị nghiệm thu — **đó** mới là phán
quyết. So ảnh chụp: ảnh baseline là snapshot đóng băng (luật N2: chụp lại baseline = lần nghiệm thu mới,
ngưỡng sai khác khai trước).

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
- [ ] Việc vừa xong có **đơn vị nghiệm thu tất định** (§4.1): đã khai trước khi code, đã thấy ĐỎ trên
      nhánh nền, giờ XANH qua `./scripts/check.sh --acceptance`. "Chạy thử thấy output ổn" không đạt.
- [ ] Nếu vừa sửa code dựa trên "hợp đồng cũ lệch hợp đồng mới" — đã **đọc source thật** của hàm/field
      đó để xác nhận hợp đồng mới, không đoán từ tên biến hay từ thông báo lỗi một mình.

Việc này **không thay thế** review của người — nó là NGƯỠNG TỐI THIỂU trước khi đưa việc gì đó cho người
đọc coi là đáng tin. Bỏ bước này không tiết kiệm được thời gian thật, vì người đọc sẽ phải tự phát hiện
lại đúng những lỗi bước này bắt được.

## 7. Vòng lặp làm việc: Issue → worktree → implement → cổng → PR → review → merge [OPT — chỉ khi chọn O7-A]

Chi tiết (lý do từng bước, cổng G1–G5, SPEC/PLAN, run record) ở **`GIT-FLOW.md`**; nhiều repo phụ thuộc
nhau ở **`MULTI-REPO.md`** — đây chỉ là checklist thao tác:

1. `git worktree add .worktrees/<slug> -b agent/<issue-id>-<slug> origin/<nhánh-nền>` + overlap scan.
2. **Viết đơn vị nghiệm thu TRƯỚC** (`acceptance/<issue-id>-<slug>.sh`, cấp N0/N1/N2 theo SPEC, §4.1) →
   chạy trên nhánh nền → phải ĐỎ.
3. Implement trong ranh giới SPEC. **Gặp chỗ MƠ HỒ → DỪNG, hỏi ở Issue, KHÔNG tự suy diễn.**
4. `./scripts/check.sh --all && ./scripts/check.sh --acceptance` — ĐỎ thì tự sửa, đừng mở PR. (Hook
   `pre-push` chạy lại tĩnh + nghiệm thu; cài bằng `scripts/install-hooks.sh`.)
5. Chạy §6 → mở PR (`Closes #NN`) → chạy lại theo đúng mô tả PR:
   `PR_BODY="$(gh pr view <PR> --json body -q .body)" ./scripts/check.sh --acceptance` → dán vào "Phán quyết
   nghiệm thu". Không cần CI (GitHub giới hạn Actions — local-first, §4.2).
6. `/code-review` trên diff — BẮT BUỘC trước MỌI merge, ai bấm cũng vậy (chốt 2026-09-13). Mỗi finding
   → **sửa/thành test tất định** (quay lại bước 4) hoặc **bác bỏ kèm lý do** trong PR. Không finding nào
   để trống. **Điểm dừng:** lần review sau chỉ chạy trên **phần diff thêm vào kể từ lần trước** (các commit
   sửa finding), không chạy lại toàn diff — review không tất định, chạy lại toàn bộ thì finding mới sinh
   mãi. Lượt delta sạch hoặc mọi finding của nó đã xử lý ⇒ xong.
7. Merge — người bấm, hoặc agent **CHỈ khi** được trao quyền (`constitution.md`).
8. **Đóng vòng — BẮT BUỘC ngay sau merge:** `./scripts/post-merge.sh <PR> --dry-run` → đọc → chạy thật
   `./scripts/post-merge.sh <PR>`. Script chỉ làm khi PR **MERGED** và **nghiệm thu chạy LẠI trên chính
   commit merge XANH** (worktree tạm; CI [OPT] nếu có thì cũng phải SUCCESS), rồi theo thứ tự: đóng Issue
   mà PR đóng (nếu GitHub chưa tự đóng) → đóng **epic** khi mọi Issue con đã đóng và nghiệm thu riêng của
   epic XANH → raise epic/story cho plan mà PR thêm/sửa → `git worktree remove` (không `--force`) → `git branch -D` →
   xoá nhánh remote → `fetch --prune`. Chi tiết: `GIT-FLOW.md` § "Sau merge — đóng vòng". Cuối cùng
   cập nhật `HANDOFF.md`. Không đóng vòng ⇒ `git branch --list 'agent/*'` thôi còn đúng là "đang làm".

Nếu chưa chọn O7-A (đang dùng O7-B — sửa thẳng, ADR khi đảo quyết định): bỏ qua §7, dùng §3 (roadmap
§TODO) làm nguồn việc-đang-mở.

## 8. Research web (học thuật + industry) — TỰ ĐỘNG, không đợi được nhắc

> **Nguồn:** phát hiện thật trong một phiên làm việc — agent root-cause một bug (confirm-pass gộp-nhầm
> tài liệu, đo được `P=1.000 R=0.786`) bằng dữ liệu thật, mở Issue `decision-needed` liệt kê 4 phương án
> THUẦN suy luận nội bộ. Owner phải tự nhắc "research web đi" agent mới tra cứu — và khi tra, 3 nguồn
> độc lập (một benchmark ngành có SỐ ĐO, một sản phẩm production mã nguồn mở, một đề xuất OSS đang mở)
> **đều** xác nhận đúng hình dạng lỗi đã đo (precision cao/recall thấp là lỗi hệ thống của cả ngành, không
> phải hiện tượng riêng), ủng hộ trực tiếp 1 trong 4 phương án, và lộ ra thêm 1 phương án MỚI chưa từng
> nghĩ tới (confidence-gated, đối xứng với cơ chế HITL-gộp đã có). Việc này lẽ ra phải là bước MẶC ĐỊNH,
> không phải việc cần nhắc riêng mỗi lần.

**Khi nào TỰ ĐỘNG research (không đợi owner nói "research đi"):**
- Đang viết một Issue `decision-needed` (`GIT-FLOW.md` § "Hai mẫu Issue") — nghĩa là đang liệt kê phương
  án chỉ từ suy luận nội bộ, chưa đối chiếu xem ai khác đã gặp/giải bài toán này chưa.
- Root-cause một bug đã xác định THẬT (không suy đoán) nhưng cách sửa có ≥2 hướng hợp lý, không hướng
  nào rõ ràng vượt trội chỉ từ logic nội bộ.
- Sắp viết một ADR nền tảng (`CLAUDE.md` L1) cho một quyết định kiến trúc nhiều khả năng đã có tiền lệ
  ngành (giao thức, thuật toán, pattern kiến trúc phổ biến) — đừng tái phát minh trong im lặng rồi mới
  biết ngành đã có giải pháp/đã thử và thất bại.

**Không cần khi:** bug có root-cause RÕ MỘT HƯỚNG SỬA DUY NHẤT (đây là "sửa lỗi", không phải "quyết
định") · quyết định thuần nội bộ không có tương đương bên ngoài (vd đặt tên biến, cấu trúc thư mục nội
bộ) · đã research đúng câu hỏi này trong phiên gần đây (đừng lặp vô ích, trích lại kết quả cũ).

**Cách research đủ TIN CẬY để trích vào tài liệu (không phải lướt qua cho có):**
1. Tối thiểu **2-3 nguồn ĐỘC LẬP** (khác tổ chức/tác giả) — một nguồn không đủ để kết luận "ngành làm
   vậy". Ưu tiên theo thứ tự: benchmark/số đo thật > sản phẩm production đã mở mã nguồn > đề xuất/thảo
   luận OSS đang hoạt động > blog cá nhân không kèm số liệu.
2. **Đọc TOÀN VĂN trước khi trích** (`CLAUDE.md` §5.1 "Nguồn" — không ghi nguồn chưa đọc toàn văn) —
   không suy diễn kết luận từ tiêu đề/đoạn trích công cụ tìm kiếm.
3. **Đối chiếu với triệu chứng THẬT đã đo trên dữ liệu của MÌNH** trước khi áp kết luận ngành vào — số đo
   ngành (vd "recall ~50%") là THAM CHIẾU xác nhận hình dạng lỗi giống nhau, KHÔNG phải cam kết sẽ đạt
   cùng con số trên hạ tầng/dữ liệu riêng (đúng tinh thần `CLAUDE.md` §6.8 "root-cause trước khi chỉnh
   tham số" — không suy đoán số ngoài áp thẳng vào số của mình).
4. Ghi **ngày tra cứu** cạnh mỗi nguồn — trang web đổi nội dung hoặc biến mất, không bất biến như commit
   SHA.

**Ghi kết quả ở đâu (L2 SSOT — một nơi, không rải):**
- Chưa đủ để chốt quyết định → **comment trên chính Issue `decision-needed`** (không viết file riêng) —
  Issue vẫn là nguồn việc-đang-mở duy nhất.
- Đã đủ để chốt → mục **"Nguồn tham khảo ngoài"** trong ADR khi merge (`templates/adr-log.md`) — thêm dòng
  link + ngày tra cứu ngay cạnh phương án được chọn/loại trong bảng "Phương án đã xem xét", không tách
  thành mục riêng biệt khỏi lý do.

## 9. Đặt tên trong code — LUÔN tiếng Anh (bất kể ngôn ngữ tài liệu)

**Tiếng Anh, không ngoại lệ:** tên biến · hàm · class · module/package · tên **file và thư mục** · test ·
đơn vị nghiệm thu (`acceptance/<id>-<english-slug>.sh`) · slug nhánh (`agent/<id>-<english-slug>`) · tên
file plan (`YYYY-MM-DD-<english-feature>.md`) · khoá config/biến môi trường · tên cột/bảng DB · route API.

**Theo O9 (`CLAUDE.md` §11, ngôn ngữ tài liệu), KHÔNG bị luật này ép:** văn xuôi tài liệu · comment ·
chuỗi hiển thị cho người dùng/thông báo lỗi · mô tả commit/PR/Issue.

**Thuật ngữ nghiệp vụ tiếng Việt** (không có từ tiếng Anh tương đương rõ ràng) → **đặt tên tiếng Anh MỘT
lần ở Glossary** (cột "Tên trong code (EN)"), code dùng đúng tên đó. Không tự dịch mỗi chỗ một kiểu: đó là
vi phạm L2, cùng khái niệm có 3 tên. Không dùng tiếng Việt bỏ dấu (`tinhTien`, `hoa_don.py`): máy không
phân biệt được nó với tiếng Anh, người đọc không phải người Việt thì không đọc được.

**Ép bằng máy** (`check.sh --naming`, nằm trong `--all` và hook `pre-push`): tên file/thư mục được track và
tên nhánh hiện tại phải **chỉ gồm ký tự ASCII**. **Không** bắt được: tiếng Việt bỏ dấu, định danh trong code
(mỗi ngôn ngữ một parser) ⇒ phần đó là kỷ luật + `/code-review` (G4): gặp tên không phải tiếng Anh thì là
finding, sửa hoặc bác bỏ kèm lý do.
