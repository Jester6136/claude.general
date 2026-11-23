# AI-PIPELINE.md — Minh bạch · Provenance · Độ tin cậy cho pipeline AI dày đặc (companion của CLAUDE.md)

> **File này là gì:** phần mở rộng **[OPT]** của `CLAUDE.md` (trước đây là `CLAUDE.md` §6b — tách ra
> 2026-11-23 để project không có pipeline AI khỏi phải tải ~55 dòng này mỗi phiên).
> **[TRIGGER] đọc file này khi:** project có **≥2 tầng biến-đổi-dữ-liệu-bằng-AI** (vd OCR → LLM trích xuất
> → hoà giải → UI) — khi đó coi như **BẬT mặc định**, không phải tuỳ chọn. Hoặc khi owner/PM hỏi "người
> dùng có biết dữ liệu chuyển hoá ra sao, tin được tới đâu, cải thiện được không".
> **Phụ thuộc:** `CLAUDE.md` §6 (kỷ luật số) · `AGENT.md` §4.1 (nghiệm thu tất định N0/N1/N2).

*Đúc từ một lần audit thật (2026-08-12) trên một hệ 3-repo (OCR/trích xuất → hoà giải đa nguồn → đồ thị
tri thức → agent hội thoại). Mẫu n=1 hệ thống — đọc như "đây là 6 dạng lỗ hổng có thật, đã tìm và xác
nhận bằng đọc code trực tiếp", không phải quy luật phổ quát; nhưng hình dạng lỗ hổng (constant giả làm đo
thật, chuỗi provenance đứt ở ranh giới format, cơ chế chỉ tới tay vai vận hành chứ không tới tay
end-user, nhãn cô lập khỏi số cần hiệu chuẩn, audit trail một chiều) đủ tổng quát để đưa vào playbook.*

**Vì sao tách khỏi `CLAUDE.md` §6:** §6 kiểm tra một con số đã tồn tại có được TRÌNH BÀY trung
thực không (mẫu số, `None` vs `0.0`, coverage). File này đứng TRƯỚC §6 một bước — hỏi con số đó **có thật
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
   ⇒ Mỗi con số đang được tin phải có golden set riêng chạm tới nó — đó chính là đơn vị nghiệm thu
   cấp **N2** (`AGENT.md` §4.1); không có thì phán quyết về con số đó chưa tồn tại.
4. **Feedback được GHI hay được ĐỌC LẠI?** Một cơ chế ghi log/audit khi người dùng phản hồi (chấp
   nhận/sửa/từ chối một đề xuất do AI tạo) là **audit trail MỘT CHIỀU** cho tới khi có thứ gì đó THẬT SỰ
   đọc lại nó để đổi hành vi (prompt, ngưỡng, tập eval, cảnh báo tỉ lệ từ chối cao). *Anti-pattern đã
   gặp:* ba đường ghi feedback riêng biệt, đủ dữ liệu, chạy ổn định nhiều tháng — grep toàn hệ thống cho
   bất kỳ job/route nào ĐỌC LẠI các bảng đó để hành động: không có. Trước khi trả lời "agent có cải thiện
   được không" bằng "có, vì chúng tôi ghi log" — hỏi tiếp: *ai đọc log đó, và làm gì khác đi sau khi đọc?*

**Khi audit xong — sản phẩm là gì:** KHÔNG code ngay. Bốn câu hỏi trên thường lộ ra quyết định owner phải
chốt hướng (đầu tư hiệu chuẩn ở đâu trước, mức độ hiện ra UI, có kích hoạt vòng cải thiện hay chưa) —
đây đúng là loại nội dung "cần trao đổi trước khi thành việc code" mà `CLAUDE.md` §11b nói tới; xem
**`GIT-FLOW.md` § "GitHub Discussions — trước khi thành Issue"** để biết đăng ở đâu, và **đừng** tự
quyết thay owner rồi mở PR luôn.
