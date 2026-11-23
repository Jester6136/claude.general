#!/usr/bin/env bash
# scripts/check.sh — cổng chất lượng DUY NHẤT. LOCAL-FIRST: máy dev/agent, hook pre-push và post-merge.sh
# gọi ĐÚNG script này; CI là [OPT] (GitHub giới hạn Actions) và nếu bật cũng chỉ gọi script này — không
# viết lại logic kiểm trong .github/workflows/*.yml ("máy tôi xanh mà CI đỏ", GIT-FLOW.md).
#
# Script, không Makefile: máy dev/run có thể KHÔNG có `make`; nếu project bạn chắc chắn có `make`, gọi
# lại từ đó (`check: ; ./scripts/check.sh`), đừng viết trùng logic.
#
# ⚠ TUYỆT ĐỐI không dùng nháy kép quanh dòng nhắc có backtick trong đó — bash coi backtick trong nháy
# kép là command substitution và CHẠY THẬT (bài học thật: dòng nhắc "cài bằng `pip install ruff`" từng
# tự cài ruff vào máy). Dùng nháy đơn cho mọi chuỗi hiển thị.
#
# ⚠ ${CI:-} do GitHub Actions tự set — dùng làm fallback: không có service sống (docker/db) VÀ
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

# ── Đặt tên — tên file/thư mục/nhánh chỉ ASCII (AGENT.md §9: tên trong code LUÔN tiếng Anh) ──
# Bắt được: ký tự ngoài ASCII (tiếng Việt có dấu) trong tên file/thư mục được track và tên nhánh hiện tại.
# KHÔNG bắt được: tiếng Việt bỏ dấu, định danh bên trong code ⇒ kỷ luật + /code-review (finding).
run_naming() {
  echo
  echo "Đặt tên — file/thư mục/nhánh chỉ ASCII (AGENT.md §9)"
  local bad br
  bad="$(git -c core.quotepath=off ls-files 2>/dev/null | LC_ALL=C grep '[^ -~]' || true)"
  if [ -n "$bad" ]; then
    fail "tên file/thư mục ngoài ASCII — đổi sang tiếng Anh: $(printf '%s\n' "$bad" | head -5 | tr '\n' ' ')"
  else
    pass "tên file/thư mục: chỉ ASCII"
  fi
  br="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if LC_ALL=C grep -q '[^ -~]' <<<"$br"; then fail "tên nhánh ngoài ASCII: $br"; else pass "tên nhánh: chỉ ASCII"; fi
}

# ── Nghiệm thu TẤT ĐỊNH (AGENT.md §4) — chạy riêng bằng --acceptance ─────────
# Mỗi đơn vị = một file acceptance/<issue-id>-<slug>.sh. Exit 0 = ĐẠT · 77 = không chạy được (thiếu dữ
# liệu/hạ tầng) · khác = KHÔNG ĐẠT. KHÁC các bước trên: SKIP (77) tính là ĐỎ — một đơn vị nghiệm thu đã
# khai mà không chạy được thì chưa nghiệm thu. Mỗi đơn vị chạy 2 lần; PHÁN QUYẾT lệch = FLAKY = ĐỎ (không
# tất định thì không được làm phán quyết; 2 lần chỉ bắt lệch THÔ, không chứng minh tất định).
# Không có đơn vị nào = SKIP (hiện cảnh báo, không đỏ — repo mới chưa nghiệm thu gì là hợp lệ).
# Issue BẮT BUỘC có đơn vị (thiếu acceptance/<N>-*.sh = ĐỎ — ép bằng máy, CLAUDE.md L7). Lấy từ ĐÚNG MỘT nguồn:
#   (a) ACCEPTANCE_REQUIRED_IDS="42 43" nếu KHÁC RỖNG — ghi đè (b)/(c);
#   (b) khi PR_BODY được truyền (kể cả rỗng) — post-merge.sh tự truyền mô tả PR; tay:
#       PR_BODY="$(gh pr view <N> --json body -q .body)"; CI [OPT] cũng truyền: CHỈ từ khoá đóng của GitHub
#       `Closes/Fixes/Resolves[:] #N` — PR chỉ `Refs #42` thì không bị đòi, dù nhánh tên agent/42-*;
#   (c) không có PR_BODY: tên nhánh `agent/<N>-<slug>` — xấp xỉ (b), KHỚP khi PR của nhánh đóng đúng #N.
#       Khác nhau (vd PR đóng #43 từ agent/42-*) thì (b) — tức lần chạy lại trong post-merge.sh — là phán quyết.
# KHÔNG bắt được: đóng Issue qua URL đầy đủ, qua sidebar "Development", qua từ khoá trong commit message.
# N2: đơn vị chỉ CHẤM LẠI snapshot đã đóng băng — KHÔNG gọi model sống ở đây (đó là tầng B).
acceptance_ids() {
  if [ -n "${ACCEPTANCE_REQUIRED_IDS:-}" ]; then echo "$ACCEPTANCE_REQUIRED_IDS"; return 0; fi
  if [ -n "${PR_BODY+x}" ]; then
    printf '%s\n' "$PR_BODY" \
      | grep -oiE '(^|[^[:alnum:]_])(close[sd]?|fix(e[sd])?|resolve[sd]?):? +#[0-9]+' \
      | grep -oE '#[0-9]+' | tr -d '#' | sort -u | tr '\n' ' ' || true
  else
    git rev-parse --abbrev-ref HEAD 2>/dev/null | sed -nE 's#^agent/([0-9]+)-.*#\1#p' || true
  fi
}
verdict_of() { case "$1" in 0) echo ĐẠT ;; 77) echo KHÔNG-CHẠY ;; *) echo KHÔNG-ĐẠT ;; esac; }
run_acceptance() {
  echo
  echo "Nghiệm thu tất định (acceptance/*.sh, mỗi đơn vị chạy 2 lần)"
  local dir="${ACCEPTANCE_DIR:-acceptance}" unit rc1 rc2 v1 v2 id n=0
  local ids; ids="$(acceptance_ids)"
  echo "  · Issue bắt buộc có đơn vị nghiệm thu: ${ids:-(không có)}"
  local -a id_list=(); read -ra id_list <<<"$ids" || true   # read -ra: tách theo khoảng trắng, KHÔNG glob
  for id in ${id_list[@]+"${id_list[@]}"}; do
    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
      fail "ID Issue không hợp lệ '$id' (chỉ nhận số, vd ACCEPTANCE_REQUIRED_IDS=\"42 43\")"; continue
    fi
    if compgen -G "$dir/$id-*.sh" >/dev/null; then
      pass "Issue #$id có đơn vị nghiệm thu"
    else
      fail "Issue #$id được đóng nhưng KHÔNG có $dir/$id-*.sh — khai đơn vị nghiệm thu trước khi merge"
    fi
  done
  for unit in "$dir"/*.sh; do
    [ -e "$unit" ] || continue
    n=$((n+1))
    rc1=0; bash "$unit" >/dev/null 2>&1 || rc1=$?
    rc2=0; bash "$unit" >/dev/null 2>&1 || rc2=$?
    v1=$(verdict_of "$rc1"); v2=$(verdict_of "$rc2")
    if [ "$v1" != "$v2" ]; then
      fail "$unit — FLAKY: lần 1 $v1 (exit=$rc1), lần 2 $v2 (exit=$rc2) — cách ly + mở Issue, KHÔNG retry cho xanh"
    elif [ "$v1" = KHÔNG-CHẠY ]; then
      fail "$unit — không chạy được (exit 77): đơn vị đã khai mà không chạy = CHƯA nghiệm thu"
    elif [ "$v1" = ĐẠT ]; then
      pass "$unit"
    else
      fail "$unit — KHÔNG ĐẠT (exit=$rc1). Chạy tay để xem chi tiết: bash $unit"
    fi
  done
  [ "$n" -eq 0 ] && skip "0 đơn vị nghiệm thu trong $dir/ — CHƯA nghiệm thu gì; việc đóng từ nay phải thêm đơn vị của nó"
  return 0
}

case "$MODE" in
  --syntax)  run_syntax ;;
  --boundary) run_boundary ;;
  --lint)    run_lint ;;
  --smoke|--test|--pytest) run_tests ;;
  --acceptance) run_acceptance ;;
  --naming)  run_naming ;;
  --all)
    run_naming
    run_syntax
    run_boundary
    run_lint
    run_tests
    ;;
  *)
    echo "Dùng: $0 [--naming|--syntax|--boundary|--lint|--smoke|--all|--acceptance]" >&2
    exit 2
    ;;
esac

echo
echo "KẾT QUẢ: $([ "$FAIL" -eq 0 ] && echo XANH || echo ĐỎ)  pass=$PASS fail=$FAIL skip=$SKIP"
if [ "$SKIP" -gt 0 ]; then
  echo "⚠ $SKIP cổng bị BỎ QUA — xanh ở đây KHÔNG có nghĩa là đã kiểm hết." >&2
fi
[ "$FAIL" -eq 0 ]
