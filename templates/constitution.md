# constitution.md — luật hằng số cho MỌI phiên agent [OPT]

> **Khi nào cần file này** (xem `GIT-FLOW.md` §11b): agent bắt đầu **lặp lại cùng một lỗi phạm vi/style ở
> nhiều Issue khác nhau**. **Chưa cần:** project mới, ít agent-session — ADR nền tảng (`adr-log.md`) đang
> đủ. Đừng tạo file này ở Sprint 0 "cho chắc" — nó chỉ có giá trị khi có bằng chứng lặp lại thật.

Khác `adr-log.md` (quyết định gắn bối cảnh, có thể Superseded): đây là hằng số áp cho MỌI phiên, không
gắn bối cảnh nào. Sửa qua PR như tài liệu thường — Loại 1/2 (`CLAUDE.md` §L4), không cần ADR trừ khi đảo
ngược một luật đã có ở đây.

## Quy ước code style bắt buộc
<vd: format qua `<tool>`, không tự tạo quy ước riêng>

## Danh sách file/thư mục CẤM ĐỤNG toàn cục
<Khác "phạm vi cấm" của riêng một Issue — đây là cấm ở MỌI Issue, mọi lúc.>
- `<path>` — <vì sao>

## Lệnh luôn phải chạy trước khi mở PR
```bash
<lệnh — thường là ./scripts/check.sh --all>
```

## Trao quyền merge cho Agent [OPT]
Mặc định: KHÔNG cấp — chủ dự án tự merge sau khi nghiệm thu tất định XANH và mọi finding `/code-review`
đã xử lý (`GIT-FLOW.md` § "Năm cổng"). Nếu cấp, ghi rõ phạm vi ở đây (loại Issue nào):
<vd: "Agent được tự merge Issue nhãn `agent-ready` cấp N0/N1 khi `check.sh --acceptance` XANH và KHÔNG có
finding nào bị bác bỏ; Issue cấp N2, `decision-needed`, hoặc liên quan >1 repo luôn cần chủ dự án tự bấm.">

