#!/usr/bin/env bash
# scripts/post-merge.sh <PR-number> [--dry-run] — ĐÓNG VÒNG sau khi một PR đạt nghiệm thu và đã merge
# (AGENT.md §7 bước 8, GIT-FLOW.md § "Sau merge — đóng vòng"). Chạy ở MÁY DEV/agent (không phải CI) vì
# worktree và nhánh local chỉ tồn tại ở đó.
#
# Làm theo đúng thứ tự, DỪNG ở cổng đầu tiên không qua — không có đường tắt:
#   0. Cổng: PR phải MERGED và MỌI check của PR phải SUCCESS (gồm `check.sh --acceptance`). Không đạt
#      nghiệm thu thì KHÔNG đóng gì, KHÔNG xoá gì.
#   1. Đóng Issue mà PR tuyên bố đóng (`closingIssuesReferences`) nếu GitHub chưa tự đóng (vd liên-repo).
#   2. Đóng EPIC: mọi Issue mở có nhãn `epic` mà (sub-issue của nó ∪ `#N` trong body) chứa Issue vừa đóng
#      VÀ tất cả đã đóng VÀ đơn vị nghiệm thu riêng của epic (acceptance/<E>-*.sh, nếu có) XANH trên HEAD
#      hiện tại ⇒ đóng epic kèm comment. Thiếu điều kiện nào thì chỉ báo, không đóng.
#   3. Dọn: `git worktree remove` (KHÔNG --force — worktree còn thay đổi chưa commit thì dừng, báo) →
#      `git branch -D` (an toàn vì bước 0 đã xác nhận MERGED; squash/rebase merge làm `-d` từ chối) →
#      xoá nhánh remote nếu còn → `git fetch --prune`.
#
# --dry-run: in ra mọi việc SẼ làm, không thay đổi gì (chạy cái này trước khi tin script trên repo mới).
set -euo pipefail

PR="${1:-}"; DRY=0; [ "${2:-}" = "--dry-run" ] && DRY=1
[[ "$PR" =~ ^[0-9]+$ ]] || { echo 'Dùng: scripts/post-merge.sh <PR-number> [--dry-run]' >&2; exit 2; }
command -v gh >/dev/null || { echo '✗ cần gh CLI' >&2; exit 2; }

run() { if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else echo "  \$ $*"; "$@"; fi; }
repo_root="$(git rev-parse --show-toplevel)"

# ── 0. Cổng: MERGED + mọi check SUCCESS ─────────────────────────────────────
state="$(gh pr view "$PR" --json state -q .state)"
[ "$state" = MERGED ] || { echo "✗ PR #$PR đang $state, chưa MERGED — không đóng/không dọn gì." >&2; exit 1; }
bad_checks="$(gh pr view "$PR" --json statusCheckRollup \
  -q '[.statusCheckRollup[] | select((.conclusion // .state) != "SUCCESS") | "\(.name // .context)=\(.conclusion // .state)"] | join(", ")')"
n_checks="$(gh pr view "$PR" --json statusCheckRollup -q '.statusCheckRollup | length')"
if [ "$n_checks" -eq 0 ]; then
  echo "✗ PR #$PR không có check nào — không có phán quyết nghiệm thu, không đóng gì." >&2; exit 1
fi
if [ -n "$bad_checks" ]; then
  echo "✗ PR #$PR có check chưa SUCCESS: $bad_checks — chưa đạt nghiệm thu, không đóng gì." >&2; exit 1
fi
head="$(gh pr view "$PR" --json headRefName -q .headRefName)"
echo "✓ PR #$PR MERGED, $n_checks/$n_checks check SUCCESS — nhánh: $head"

# ── 1. Issue mà PR đóng ──────────────────────────────────────────────────────
closed_ids="$(gh pr view "$PR" --json closingIssuesReferences -q '.closingIssuesReferences[].number' | sort -u)"
echo; echo "1. Issue PR này đóng: ${closed_ids:-(không có)}"
for id in $closed_ids; do
  if [ "$(gh issue view "$id" --json state -q .state)" = OPEN ]; then
    run gh issue close "$id" --comment "Đóng sau khi PR #$PR merge và đạt nghiệm thu (post-merge.sh)."
  else
    echo "  ✓ #$id đã đóng"
  fi
done

# ── 2. Epic ──────────────────────────────────────────────────────────────────
echo; echo "2. Epic (nhãn \`epic\`) liên quan"
epics="$(gh issue list --label epic --state open --json number -q '.[].number' 2>/dev/null || true)"
[ -n "$epics" ] || echo "  ✓ không có epic nào đang mở"
for epic in $epics; do
  children="$( { gh api "repos/{owner}/{repo}/issues/$epic/sub_issues" -q '.[].number' 2>/dev/null || true
                 gh issue view "$epic" --json body -q .body | grep -oE '(^|[^[:alnum:]_&])#[0-9]+' | grep -oE '[0-9]+' || true
               } | sort -u)"
  touches=0; for id in $closed_ids; do grep -qx "$id" <<<"$children" && touches=1; done
  [ "$touches" -eq 1 ] || continue
  open_children=""
  for c in $children; do
    st="$(gh issue view "$c" --json state -q .state 2>/dev/null || echo UNKNOWN)"
    # Issue vừa đóng ở bước 1 lúc dry-run vẫn còn OPEN trên GitHub — coi như đã đóng.
    if [ "$st" != CLOSED ] && ! grep -qx "$c" <<<"$closed_ids"; then open_children="$open_children #$c"; fi
  done
  if [ -n "$open_children" ]; then
    echo "  · Epic #$epic còn mở:$open_children — chưa đóng"; continue
  fi
  epic_red=""
  for unit in "$repo_root"/acceptance/"$epic"-*.sh; do
    [ -e "$unit" ] || continue
    bash "$unit" >/dev/null 2>&1 || epic_red="$epic_red $(basename "$unit")"
  done
  if [ -n "$epic_red" ]; then
    echo "  ✗ Epic #$epic: mọi con đã đóng nhưng đơn vị nghiệm thu của epic ĐỎ:$epic_red — chưa đóng"; continue
  fi
  run gh issue close "$epic" --comment "Mọi Issue con đã đóng (cuối cùng: PR #$PR) và nghiệm thu của epic XANH (post-merge.sh)."
done

# ── 3. Dọn worktree + nhánh ──────────────────────────────────────────────────
echo; echo "3. Dọn worktree/nhánh '$head'"
wt="$(git worktree list --porcelain | awk -v b="refs/heads/$head" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w}')"
if [ -n "$wt" ]; then
  if [ "$wt" = "$repo_root" ]; then
    echo "  ✗ Đang đứng TRONG nhánh '$head' ở worktree chính — checkout nhánh khác rồi chạy lại." >&2; exit 1
  fi
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then
    echo "  ✗ Worktree $wt còn thay đổi chưa commit — KHÔNG xoá (không --force). Xử lý tay rồi chạy lại." >&2; exit 1
  fi
  run git worktree remove "$wt"
else
  echo "  ✓ không có worktree cho nhánh này"
fi
if git show-ref --verify --quiet "refs/heads/$head"; then run git branch -D "$head"; else echo "  ✓ không còn nhánh local"; fi
if git ls-remote --exit-code --heads origin "$head" >/dev/null 2>&1; then
  run git push origin --delete "$head"
else
  echo "  ✓ không còn nhánh remote"
fi
run git fetch --prune --quiet
echo; echo "✓ Đóng vòng PR #$PR xong. Còn lại: cập nhật HANDOFF.md (AGENT.md §7 bước 8)."
