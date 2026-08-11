#!/usr/bin/env bash
# scripts/check.sh — cổng chất lượng DUY NHẤT. Máy dev VÀ CI đều gọi ĐÚNG script này — không viết lại
# logic kiểm trong .github/workflows/*.yml (nguồn kinh điển của "máy tôi xanh mà CI đỏ", GIT-FLOW.md).
#
# Script, không Makefile: máy dev/run có thể KHÔNG có `make`; nếu project bạn chắc chắn có `make`, gọi
# lại từ đó (`check: ; ./scripts/check.sh`), đừng viết trùng logic.
#
# ⚠ TUYỆT ĐỐI không dùng nháy kép quanh dòng nhắc có backtick trong đó — bash coi backtick trong nháy
# kép là command substitution và CHẠY THẬT (bài học thật: dòng nhắc "cài bằng `pip install ruff`" từng
# tự cài ruff vào máy). Dùng nháy đơn cho mọi chuỗi hiển thị.
#
# ⚠ ${CI:-} do GitHub Actions/GitLab CI tự set — dùng làm fallback: không có service sống (docker/db) VÀ
# đang CI → chạy native thay vì skip, để CI vẫn kiểm được logic thuần dù không có hạ tầng app.
set -euo pipefail

# Bytecode/pycache tràn ra ngoài repo — tránh "cổng tự tạo rác rồi tự vấp" (bài học thật: compileall rải
# __pycache__, bước tìm module smoke bằng grep -rl khớp trúng docstring nằm trong .pyc → sinh module ma).
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/pycache-check"

PASS=0
FAIL=0
SKIP=0

pass() { echo "  ✓ $*"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP: $*"; SKIP=$((SKIP+1)); }

MODE="${1:---all}"

# ── 1/4 · Cú pháp (compile toàn bộ, không thực thi) ──────────────────────────
# TODO: thay bằng lệnh compile/parse-check của ngôn ngữ bạn dùng.
# Python:  python -m compileall -q <src_dir>
# Node:    node --check <file> (hoặc tsc --noEmit)
run_syntax() {
  echo
  echo "1/4 · Cú pháp"
  # if python -m compileall -q src; then pass "compileall: src"; else fail "compileall"; fi
  skip "TODO: điền lệnh compile/parse-check ở scripts/check.sh::run_syntax"
}

# ── 2/4 · Ranh giới kiến trúc (phân tích TĨNH — đọc AST, KHÔNG chạy code) ────
# TODO: import-linter (Python) hoặc tương đương ngôn ngữ bạn dùng. Ba bẫy đã dính (GIT-FLOW.md §11b):
#   (1) thư mục thiếu __init__.py = namespace package → công cụ BỎ QUA SẠCH module bên trong, đếm số
#       tệp được phân tích và đối chiếu số tệp thật trước khi tin kết quả "xanh".
#   (2) contract `forbidden` tính CẢ chuỗi gián tiếp → phân thứ bậc phải dùng contract `layers`.
#   (3) không có ranh giới kiến trúc rõ ràng ở project nhỏ → SKIP hợp lệ, đừng bịa contract giả.
run_boundary() {
  echo
  echo "2/4 · Ranh giới kiến trúc (phân tích TĨNH)"
  skip "repo CHƯA có config ranh giới kiến trúc — chỉ nằm trong văn xuôi, không ai chặn"
}

# ── 3/4 · Lint — CHỈ nhóm bắt LỖI THẬT ───────────────────────────────────────
# Bật cả bộ rule mặc định thường ra hàng trăm lỗi style → cổng đỏ-sẵn → người ta tắt đi → mất tác dụng.
# Chỉ bật nhóm ĐANG XANH và bắt được lỗi thật: cú pháp sai · so sánh sai kiểu · dùng tên chưa định nghĩa.
# TODO: Python (ruff):  ruff check --select E9,F63,F7,F82 <src_dir>
run_lint() {
  echo
  echo "3/4 · Lint — nhóm bắt LỖI THẬT"
  skip "TODO: điền lệnh lint hẹp ở scripts/check.sh::run_lint"
}

# ── 4/4 · Smoke thuần + test plumbing (Tầng A — xem AGENT.md §4) ────────────
# Tầng A = KHÔNG chạm GPU/DB-sống/network. Tầng B (eval/e2e cần hạ tầng thật) KHÔNG được gọi ở đây —
# liệt kê cụ thể module tầng B trong AGENT.md §4, đừng để CI tự khám phá qua timeout.
run_tests() {
  echo
  echo "4/4 · Smoke thuần + test plumbing (Tầng A)"
  local mode
  if command -v docker >/dev/null 2>&1 && docker compose ps --status running --services 2>/dev/null | grep -q .; then
    mode="docker"
  elif [ -n "${CI:-}" ]; then
    mode="native"
    echo "  (CI: không có container sống — chạy thẳng trên interpreter đã cài dependency)"
  else
    skip "không có service sống và không phải CI → test KHÔNG được kiểm (docker compose up -d hoặc chạy native)"
    return
  fi
  # TODO: điền lệnh chạy test tầng A thật, theo $mode.
  # Python native:  python -m pytest tests/ -q --no-header
  skip "TODO: điền lệnh test tầng A ở scripts/check.sh::run_tests (mode=$mode)"
}

case "$MODE" in
  --syntax)  run_syntax ;;
  --boundary) run_boundary ;;
  --lint)    run_lint ;;
  --smoke|--test|--pytest) run_tests ;;
  --all)
    run_syntax
    run_boundary
    run_lint
    run_tests
    ;;
  *)
    echo "Dùng: $0 [--syntax|--boundary|--lint|--smoke|--all]" >&2
    exit 2
    ;;
esac

echo
echo "KẾT QUẢ: $([ "$FAIL" -eq 0 ] && echo XANH || echo ĐỎ)  pass=$PASS fail=$FAIL skip=$SKIP"
if [ "$SKIP" -gt 0 ]; then
  echo "⚠ $SKIP cổng bị BỎ QUA — xanh ở đây KHÔNG có nghĩa là đã kiểm hết." >&2
fi
[ "$FAIL" -eq 0 ]
