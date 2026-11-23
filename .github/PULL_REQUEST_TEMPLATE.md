<!-- Xem AGENT.md §7 / GIT-FLOW.md trước khi mở PR. Chạy AGENT.md §6 (checklist bằng chứng) trước khi
     điền form này — đừng viết "đã xong" nếu chưa thực sự chạy lại verify trong phiên hiện tại.
     Chấp nhận = phán quyết nghiệm thu TẤT ĐỊNH XANH (AGENT.md §4.1). /code-review BẮT BUỘC chạy trước
     merge nhưng chỉ SINH finding — xử lý hết ở mục cuối (GIT-FLOW.md § "Năm cổng", G4). -->

Closes #<NN>
<!-- Chạm >1 repo? Đóng Issue ở repo khác: Closes owner/repo#N (GIT-FLOW.md §11c) -->

## Gốc rễ + fix (1-2 câu)


## Phán quyết nghiệm thu (tất định)
- Đơn vị: `acceptance/<NN>-<slug>.sh` — cấp N0 / N1 / N2
- Trên nhánh nền (trước fix) — phải ĐỎ:
```
$ 
```
- Trên nhánh này — `./scripts/check.sh --acceptance`:
```
$ 
```
<!-- N2: liệt kê MỌI lần sinh snapshot cho Issue này, không chỉ lần đẹp nhất (AGENT.md §4.1). -->
| Lần | Hash snapshot | Model@version · prompt-version | Kết quả (tử/mẫu) | Ngưỡng khai trong Issue | Phán quyết |
|---|---|---|---|---|---|
| 1 | | | | | |

## Finding của /code-review — xử lý TỪNG cái, không để trống
| Finding | Xử lý | Bằng chứng |
|---|---|---|
| | ✅ thành test `<tên test>` / 🛠 sửa thẳng / ❌ bác bỏ | lý do bác bỏ, hoặc test đỏ→xanh |

## Còn dở (nếu có)


<!-- [OPT] Run record — chỉ cần nếu agent có quyền thực thi thật (shell/network), xem GIT-FLOW.md §11b.
## Run record
- Quyền công cụ: <đọc/ghi file · network · shell>
- Model: <tên + version>
- Ngoại lệ chính sách (nếu có): <vd bỏ qua 1 rule lint cụ thể, vì sao>
-->
