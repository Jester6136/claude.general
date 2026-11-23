#!/usr/bin/env bash
# scripts/post-merge.sh <PR-number> [--dry-run] — ĐÓNG VÒNG sau khi một PR đạt nghiệm thu và đã merge
# (AGENT.md §7 bước 8, GIT-FLOW.md § "Sau merge — đóng vòng"). Chạy ở MÁY DEV/agent, không phải CI:
# worktree và nhánh local chỉ tồn tại ở đó.
#
#   0. KIỂM TRƯỚC, CHƯA LÀM GÌ: PR MERGED · không còn check chưa xong · check MỚI NHẤT của từng (workflow,
#      job) đều SUCCESS (run CANCELLED do chạy lại không tính) · 0 check = không đạt · điều kiện dọn nhánh/worktree (bẩn/đang đứng trong nó
#      thì DỪNG NGAY, trước khi đóng bất cứ Issue nào).
#   1. Issue mà PR đóng (`closingIssuesReferences`, giữ đúng repo của từng Issue): Issue CÙNG repo phải
#      có acceptance/<N>-*.sh trên origin/<base> — thiếu ⇒ MỞ LẠI kèm comment (đóng mà không nghiệm thu là
#      lỗ, kể cả khi đóng qua commit message/sidebar mà CI không thấy). Còn mở ⇒ đóng.
#   2. EPIC (nhãn `epic`): con = sub-issue (phân trang đủ) ∪ dòng task-list `- [ ] [owner/repo]#N` trong body
#      epic — CHỈ link tường minh, định danh đủ owner/repo#N (con có thể ở repo khác). Issue khai ô "Epic" mà chưa được link ⇒ cảnh báo, KHÔNG đóng epic (không biết đủ tập
#      con). Đóng khi mọi con đã đóng VÀ acceptance/epic/<E>/*.sh XANH qua
#      `check.sh --acceptance` (2 lần, flaky = đỏ) trên HEAD == origin/<base>.
#   3. Dọn — CHỈ nhánh `agent/*` của chính repo này (không fork, không develop/release): worktree remove
#      (không --force) → branch -D → xoá nhánh remote.
#
# --dry-run: không đóng/mở/xoá gì, KHÔNG chạy đơn vị nghiệm thu. Vẫn `git fetch` (chỉ cập nhật ref remote,
# không đổi working tree) vì phán quyết cần đọc origin/<base> mới nhất.
set -euo pipefail

PR="${1:-}"; DRY=0; [ "${2:-}" = "--dry-run" ] && DRY=1
[[ "$PR" =~ ^[0-9]+$ ]] || { echo 'Dùng: scripts/post-merge.sh <PR-number> [--dry-run]' >&2; exit 2; }
command -v gh >/dev/null || { echo '✗ cần gh CLI' >&2; exit 2; }
die() { echo "✗ $*" >&2; exit 1; }
run() { if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else echo "  \$ $*"; "$@"; fi; }
pr() { gh pr view "$PR" --json "$1" -q "$2"; }

repo_root="$(git rev-parse --show-toplevel)"; cd "$repo_root"
main_wt="$(git worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')"
this_repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# ── 0. Kiểm trước ────────────────────────────────────────────────────────────
[ "$(pr state .state)" = MERGED ] || die "PR #$PR chưa MERGED — không đóng/không dọn gì."
# Còn check chưa xong (queued/in-progress/pending) ⇒ chưa có phán quyết cuối — dừng, không so "mới nhất"
# (gh trả completedAt của run chưa xong là 0001-01-01…, sẽ thua run cũ đã xong).
pending="$(pr statusCheckRollup '[.statusCheckRollup[] | select((.status // "COMPLETED") != "COMPLETED" or .state == "PENDING" or .state == "EXPECTED") | (.name // .context)] | join(", ")')"
[ -z "$pending" ] || die "PR #$PR còn check chưa chạy xong: $pending — chờ phán quyết rồi chạy lại. Chưa đóng gì."
# Mới nhất theo (workflow, tên job): 2 workflow cùng có job `check` là 2 phán quyết riêng, không che nhau.
LATEST='[.statusCheckRollup | group_by([(.workflowName // ""), (.name // .context)])[] | max_by(.completedAt // .startedAt // "")]'
n_checks="$(pr statusCheckRollup "$LATEST | length")"
[ "$n_checks" -gt 0 ] || die "PR #$PR không có check nào — không có phán quyết nghiệm thu, không đóng gì."
bad="$(pr statusCheckRollup "$LATEST | map(select((.conclusion // .state) != \"SUCCESS\")) | map(\"\(.workflowName // \"\")/\(.name // .context)=\(.conclusion // .state)\") | join(\", \")")"
[ -z "$bad" ] || die "PR #$PR có check (lần chạy mới nhất) chưa SUCCESS: $bad — chưa đạt nghiệm thu, không đóng gì."
head="$(pr headRefName .headRefName)"; base="$(pr baseRefName .baseRefName)"
cross="$(pr isCrossRepository .isCrossRepository)"
echo "✓ PR #$PR MERGED, $n_checks/$n_checks check SUCCESS (lần mới nhất) — $head → $base"
git fetch --quiet --prune origin

clean=0; wt=""
if [[ "$head" == agent/* ]] && [ "$cross" = false ]; then
  clean=1
  wt="$(git worktree list --porcelain | awk -v b="refs/heads/$head" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w}')"
  [ "$wt" != "$repo_root" ] || die "Đang đứng TRONG worktree sẽ bị xoá ($wt) — chạy lại từ worktree chính ($main_wt). Chưa đóng gì."
  [ "$wt" != "$main_wt" ] || die "Nhánh '$head' đang checkout ở worktree chính ($main_wt) — checkout nhánh khác rồi chạy lại. Chưa đóng gì."
  [ -z "$wt" ] || [ -z "$(git -C "$wt" status --porcelain)" ] || die "Worktree $wt còn thay đổi chưa commit — xử lý tay rồi chạy lại (không --force). Chưa đóng gì."
else
  echo "  · Sẽ KHÔNG dọn nhánh '$head': chỉ dọn nhánh agent/* của chính repo (cross-repo=$cross)."
fi

# ── 1. Issue mà PR đóng ──────────────────────────────────────────────────────
echo; echo "1. Issue PR này đóng"
refs="$(pr closingIssuesReferences '.closingIssuesReferences[] | "\(.repository.owner.login)/\(.repository.name)#\(.number)"')"
[ -n "$refs" ] || echo "  (không có)"
closed_local=""; closed_refs=""
for ref in $refs; do
  repo="${ref%#*}"; n="${ref#*#}"
  st="$(gh issue view "$n" -R "$repo" --json state -q .state)"
  if [ "$repo" = "$this_repo" ]; then
    if ! git ls-tree -r --name-only "origin/$base" -- acceptance/ | grep -qE "^acceptance/$n-[^/]*\.sh$"; then
      echo "  ✗ #$n đóng mà KHÔNG có acceptance/$n-*.sh trên origin/$base"
      [ "$st" = CLOSED ] && run gh issue reopen "$n" --comment "Mở lại: PR #$PR đóng Issue này nhưng không có đơn vị nghiệm thu acceptance/$n-*.sh (AGENT.md §4). Khai đơn vị + PR mới."
      continue
    fi
    closed_local="$closed_local $n"; closed_refs="$closed_refs $this_repo#$n"
  else
    echo "  · $ref ở repo khác — đơn vị nghiệm thu thuộc repo đó (GIT-FLOW.md §11c)"
  fi
  if [ "$st" = OPEN ]; then run gh issue close "$n" -R "$repo" --comment "Đóng sau khi $this_repo#$PR merge và đạt nghiệm thu (post-merge.sh)."
  else echo "  ✓ $ref đã đóng"; fi
done

# ── 2. Epic ──────────────────────────────────────────────────────────────────
echo; echo "2. Epic (nhãn \`epic\`)"
epic_field() {  # ô "Epic" của issue form agent-ready: "### Epic ...\n\n#10"
  gh issue view "$1" --json body -q .body | awk '/^### Epic/{f=1;next} /^### /{f=0} f' | grep -oE '#[0-9]+' | head -1 | tr -d '#' || true
}
declare_epic=""
for n in $closed_local; do e="$(epic_field "$n")"; [ -n "$e" ] && declare_epic="$declare_epic $e"; done
epics="$( { gh issue list --label epic --state open --limit 1000 --json number -q '.[].number'; printf '%s\n' $declare_epic; } | sort -un)"
[ -n "$epics" ] || echo "  ✓ không có epic nào đang mở"
for epic in $epics; do
  [ "$(gh issue view "$epic" --json state -q .state)" = OPEN ] || continue
  # Con định danh ĐỦ owner/repo#N — sub-issue có thể ở repo khác; #4 ở repo này ≠ other/x#4.
  if ! subs="$(gh api --paginate "repos/{owner}/{repo}/issues/$epic/sub_issues" -q '.[] | "\(.repository_url | sub(".*/repos/"; ""))#\(.number)"' 2>&1)"; then
    echo "  ✗ Epic #$epic: không đọc được sub-issue ($subs) — KHÔNG đóng"; continue
  fi
  tasks="$(gh issue view "$epic" --json body -q .body | grep -oE '^[[:space:]]*[-*] \[[ xX]\] ([[:alnum:]_.-]+/[[:alnum:]_.-]+)?#[0-9]+\b' \
            | grep -oE '([[:alnum:]_.-]+/[[:alnum:]_.-]+)?#[0-9]+$' | sed -E "s|^#|$this_repo#|" || true)"
  children="$(printf '%s\n%s\n' "$subs" "$tasks" | grep -E '^[[:alnum:]_.-]+/[[:alnum:]_.-]+#[0-9]+$' | sort -u || true)"
  touches=0; unlinked=""
  for n in $closed_local; do
    if grep -qxF "$this_repo#$n" <<<"$children"; then touches=1
    elif [ "$(epic_field "$n")" = "$epic" ]; then unlinked="$unlinked #$n"; fi
  done
  if [ -n "$unlinked" ]; then
    # Tập con chỉ đáng tin khi được LINK tường minh — không suy ra từ ô tự khai của một con.
    echo "  ✗ Epic #$epic:$unlinked khai ô Epic nhưng chưa được link (sub-issue / \`- [ ] #N\` trong body epic) — KHÔNG đóng epic; link rồi chạy lại"
    continue
  fi
  [ "$touches" -eq 1 ] || continue
  open_children=""
  for c in $children; do
    st="$(gh issue view "${c#*#}" -R "${c%#*}" --json state -q .state 2>/dev/null || echo KHÔNG-PHẢI-ISSUE)"
    if [ "$st" != CLOSED ] && ! grep -qxF "$c" <<<"$(printf '%s\n' $closed_refs)"; then open_children="$open_children $c($st)"; fi
  done
  [ -z "$open_children" ] || { echo "  · Epic #$epic còn:$open_children — chưa đóng"; continue; }
  unit_dir="acceptance/epic/$epic"
  if git ls-tree -d --name-only "origin/$base" -- "$unit_dir" | grep -q .; then
    if [ "$DRY" -eq 1 ]; then
      echo "  [dry-run] sẽ chạy: ACCEPTANCE_DIR=$unit_dir ./scripts/check.sh --acceptance (trên origin/$base)"
    else
      [ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$base")" ] \
        || { echo "  ✗ Epic #$epic có nghiệm thu riêng: cần HEAD == origin/$base để chạy (git switch --detach origin/$base) — chưa đóng"; continue; }
      PR_BODY= ACCEPTANCE_DIR="$unit_dir" ./scripts/check.sh --acceptance >/dev/null 2>&1 \
        || { echo "  ✗ Epic #$epic: mọi con đã đóng nhưng $unit_dir ĐỎ — chưa đóng"; continue; }
      echo "  ✓ $unit_dir XANH"
    fi
  fi
  run gh issue close "$epic" --comment "Mọi Issue con đã đóng (cuối cùng: PR #$PR) và nghiệm thu của epic XANH (post-merge.sh)."
done

# ── 3. Dọn worktree + nhánh ──────────────────────────────────────────────────
echo; echo "3. Dọn nhánh '$head'"
if [ "$clean" -eq 1 ]; then
  if [ -n "$wt" ]; then run git worktree remove "$wt"; else echo "  ✓ không có worktree"; fi
  if git show-ref --verify --quiet "refs/heads/$head"; then run git branch -D "$head"; else echo "  ✓ không còn nhánh local"; fi
  if git ls-remote --exit-code --heads origin "$head" >/dev/null 2>&1; then run git push origin --delete "$head"
  else echo "  ✓ không còn nhánh remote"; fi
else
  echo "  · bỏ qua (xem bước 0)"
fi
echo; echo "✓ Đóng vòng PR #$PR xong. Còn lại: cập nhật HANDOFF.md (AGENT.md §7 bước 8)."
