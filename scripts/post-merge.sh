#!/usr/bin/env bash
# scripts/post-merge.sh <PR-number> [--dry-run] — ĐÓNG VÒNG sau khi một PR đạt nghiệm thu và đã merge
# (AGENT.md §7 bước 8, GIT-FLOW.md § "Sau merge — đóng vòng"). Chạy ở MÁY DEV/agent: worktree và nhánh
# local chỉ tồn tại ở đó. LOCAL-FIRST: KHÔNG cần CI (GitHub giới hạn Actions) — phán quyết là chạy lại
# nghiệm thu ở máy trên CHÍNH commit merge.
#
#   0. KIỂM TRƯỚC, CHƯA LÀM GÌ:
#      · PR MERGED.
#      · PHÁN QUYẾT (bắt buộc): `check.sh --acceptance` chạy lại trong worktree TẠM detached ở commit merge,
#        PR_BODY = mô tả PR (Issue nào bị đóng thì phải có đơn vị). ĐỎ ⇒ nhánh nền đang hỏng: dừng, báo người.
#      · CI [OPT]: nếu PR CÓ check thì không còn check chưa xong và lần MỚI NHẤT của từng (workflow, job)
#        đều SUCCESS (CANCELLED do chạy lại không tính). 0 check = project không bật CI — hợp lệ.
#      · Điều kiện dọn nhánh/worktree (bẩn/đang đứng trong nó ⇒ DỪNG NGAY, trước khi đóng bất cứ gì).
#   1. Issue mà PR đóng (`closingIssuesReferences`, giữ đúng repo của từng Issue): Issue CÙNG repo phải
#      có acceptance/<N>-*.sh trên origin/<base> — thiếu ⇒ MỞ LẠI kèm comment (đóng mà không nghiệm thu là
#      lỗ, kể cả khi đóng qua commit message/sidebar). Còn mở ⇒ đóng.
#   2. EPIC (nhãn `epic`): con = sub-issue (phân trang đủ) ∪ dòng task-list `- [ ] [owner/repo]#N` trong body
#      epic — CHỈ link tường minh, định danh đủ owner/repo#N. Issue khai ô "Epic" mà chưa được link ⇒ cảnh
#      báo, KHÔNG đóng epic. Đóng khi mọi con đã đóng VÀ acceptance/epic/<E>/*.sh XANH (worktree tạm ở
#      origin/<base>, 2 lần, flaky = đỏ).
#   2b. PLAN: plan `docs/superpowers/plans/*.md` mà PR thêm/sửa ⇒ `plan-to-issues.py` (worktree tạm ở commit
#      merge) raise epic/story — thay cho workflow CI. Chạy lại an toàn (marker). Tự bỏ qua khi
#      plan-to-issues.yml ở commit merge có trigger `push:` (không để 2 nơi cùng raise); PLANS_VIA_CI=1 ép bỏ qua.
#   3. Dọn — CHỈ nhánh `agent/*` của chính repo này (không fork, không develop/release): worktree remove
#      (không --force) → branch -D → xoá nhánh remote.
#
# --dry-run: không đóng/mở/xoá/tạo gì trên GitHub hay nhánh. VẪN chạy nghiệm thu (worktree tạm, xoá ngay
# sau đó) để xem trước đúng phán quyết, và `plan-to-issues.py --dry-run`. Vẫn `git fetch`.
set -euo pipefail

PR="${1:-}"; DRY=0; [ "${2:-}" = "--dry-run" ] && DRY=1
[[ "$PR" =~ ^[0-9]+$ ]] || { echo 'Dùng: scripts/post-merge.sh <PR-number> [--dry-run]' >&2; exit 2; }
command -v gh >/dev/null || { echo '✗ cần gh CLI' >&2; exit 2; }
die() { echo "✗ $*" >&2; exit 1; }
run() { if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else echo "  \$ $*"; "$@"; fi; }
pr() { gh pr view "$PR" --json "$1" -q "$2"; }

# Worktree TẠM detached ở một commit — chạy phán quyết trên đúng commit đó mà không đụng worktree đang làm.
TMP_WT=""
drop_tmp() { if [ -n "$TMP_WT" ]; then git worktree remove --force "$TMP_WT" >/dev/null 2>&1 || true; TMP_WT=""; fi; }
# KHÔNG dùng `trap … EXIT`: bash 3.2 (mặc định macOS) với `set -eu` + BẤT KỲ EXIT trap nào cho script thoát mã 0
# khi lỗi biến chưa khai báo — cổng chết giữa chừng trông như THÀNH CÔNG (đo 2026-11-23, GIT-FLOW bài học 5).
# Chỉ bẫy INT/TERM; worktree tạm được dọn tường minh (drop_tmp) sau mỗi lần dùng.
trap 'drop_tmp; exit 130' INT TERM
# Dựng worktree và chạy lệnh TÁCH thành 2 bước: lỗi dựng worktree được báo bằng chính lời gọi mk_tmp (ở shell
# hiện tại), không lẫn vào exit code của lệnh chạy bên trong (env/check.sh có thể trả bất kỳ mã nào).
mk_tmp() {  # mk_tmp <sha> — worktree tạm tách rời tại <sha>, đường dẫn ở $TMP_WT; KHÔNG gọi trong $(...)
  drop_tmp
  TMP_WT="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-XXXXXX")" || { TMP_WT=""; return 1; }
  rmdir "$TMP_WT"
  git worktree add --quiet --detach "$TMP_WT" "$1" >/dev/null </dev/null \
    || { echo "  ✗ không dựng được worktree tạm ở $1 (lỗi git ở trên)" >&2; TMP_WT=""; return 1; }
}
in_tmp() { ( cd "$TMP_WT" && "$@" ); }   # in_tmp <lệnh...> — chạy trong worktree tạm, trả exit code của lệnh

repo_root="$(git rev-parse --show-toplevel)"; cd "$repo_root"
main_wt="$(git worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')"
this_repo="$(gh repo view --json nameWithOwner -q .nameWithOwner | tr '[:upper:]' '[:lower:]')"   # GitHub không phân biệt hoa/thường

# ── 0. Kiểm trước ────────────────────────────────────────────────────────────
[ "$(pr state .state)" = MERGED ] || die "PR #$PR chưa MERGED — không đóng/không dọn gì."
head="$(pr headRefName .headRefName)"; base="$(pr baseRefName .baseRefName)"
cross="$(pr isCrossRepository .isCrossRepository)"; merge_sha="$(pr mergeCommit .mergeCommit.oid)"
body="$(pr body .body)"
git fetch --quiet --prune origin
git cat-file -e "$merge_sha^{commit}" 2>/dev/null || die "Không thấy commit merge $merge_sha sau fetch — chưa đóng gì."

# CI [OPT] — chỉ xét khi PR CÓ check. Còn check chưa xong ⇒ chưa có phán quyết cuối (gh trả completedAt của
# run chưa xong là 0001-01-01…, sẽ thua run cũ đã xong). EXPECTED = check BẮT BUỘC không ai post (vd workflow
# bị lọc paths) — chờ không bao giờ tự hết ⇒ báo riêng.
n_all="$(pr statusCheckRollup '.statusCheckRollup | length')"
if [ "$n_all" -gt 0 ]; then
  expected="$(pr statusCheckRollup '[.statusCheckRollup[] | select(.state == "EXPECTED") | (.name // .context)] | join(", ")')"
  [ -z "$expected" ] || die "PR #$PR có check bắt buộc KHÔNG BAO GIỜ được chạy (EXPECTED): $expected — chờ không tự hết; xử lý tay (chạy lại workflow, hoặc bỏ yêu cầu check đó). Chưa đóng gì."
  pending="$(pr statusCheckRollup '[.statusCheckRollup[] | select((.status // "COMPLETED") != "COMPLETED" or .state == "PENDING") | (.name // .context)] | join(", ")')"
  [ -z "$pending" ] || die "PR #$PR còn check đang chờ/chạy: $pending — chờ rồi chạy lại (QUEUED mãi ⇒ xử lý tay). Chưa đóng gì."
  # Mới nhất theo (workflow, tên job): 2 workflow cùng có job `check` là 2 phán quyết riêng, không che nhau.
  LATEST='[.statusCheckRollup | group_by([(.workflowName // ""), (.name // .context)])[] | max_by(.completedAt // .startedAt // "")]'
  bad="$(pr statusCheckRollup "$LATEST | map(select((.conclusion // .state) != \"SUCCESS\")) | map(\"\(.workflowName // \"\")/\(.name // .context)=\(.conclusion // .state)\") | join(\", \")")"
  [ -z "$bad" ] || die "PR #$PR có check CI (lần mới nhất) chưa SUCCESS: $bad — không đóng gì."
  ci_note="CI $(pr statusCheckRollup "$LATEST | length") check SUCCESS"
else
  ci_note="không có CI (tuỳ chọn)"
fi

# File PR đổi — API REST phân trang (tới 3000 file), KHÔNG `gh pr view --json files` (cắt ở 100).
pr_files="$(gh api --paginate "repos/{owner}/{repo}/pulls/$PR/files" -q '.[].filename')" \
  || die "Không đọc được danh sách file của PR #$PR — chưa đóng gì."
# PR sửa CHÍNH cổng phán quyết ⇒ phán quyết dưới đây do cổng của PR tự chấm mình. Không tự tin: người phải
# đọc diff cổng rồi xác nhận bằng GATE_CHANGE_REVIEWED=1 (dry-run chỉ cảnh báo).
# Cổng = mọi thứ post-merge CHẠY từ commit merge bằng quyền gh của người vận hành (+ workflow nếu bật CI).
gate_touched="$(grep -E '^(scripts/check\.sh|scripts/post-merge\.sh|scripts/plan-to-issues\.py|scripts/hooks/|\.github/workflows/)' <<<"$pr_files" | tr '\n' ' ' || true)"
if [ -n "$gate_touched" ]; then
  echo "⚠ PR #$PR sửa cổng phán quyết: ${gate_touched}— phán quyết dưới đây dùng cổng ĐÃ SỬA."
  [ "$DRY" -eq 1 ] || [ "${GATE_CHANGE_REVIEWED:-}" = 1 ] \
    || die "Đọc diff của cổng (git diff ${merge_sha:0:7}^1 ${merge_sha:0:7} -- $gate_touched) rồi chạy lại với GATE_CHANGE_REVIEWED=1. Chưa đóng gì."
fi

# PHÁN QUYẾT — chạy lại ở máy, trên chính commit merge (không tin lời khai trong PR, không cần CI).
echo "· Phán quyết: check.sh --acceptance trên commit merge ${merge_sha:0:7} (worktree tạm) …"
mk_tmp "$merge_sha" || die "Không dựng được worktree tạm để chạy phán quyết (xem lỗi git ở trên) — KHÔNG phải nghiệm thu đỏ. Chưa đóng gì."
rc=0; out="$(in_tmp env PR_BODY="$body" ./scripts/check.sh --acceptance 2>&1)" || rc=$?; drop_tmp
printf '%s\n' "$out" | sed -n 's/^\(  [✓✗⊘].*\)$/  \1/p'
[ "$rc" -eq 0 ] || die "Nghiệm thu trên commit merge ${merge_sha:0:7} ĐỎ (exit=$rc) — xem dòng ✗ ở trên. Đơn vị KHÔNG ĐẠT ⇒ nhánh $base đang hỏng, báo người (GIT-FLOW thông báo 4); Issue bị đóng mà thiếu đơn vị ⇒ khai đơn vị. Sửa bằng PR mới. Chưa đóng gì."
echo "✓ PR #$PR MERGED · nghiệm thu XANH trên ${merge_sha:0:7} · $ci_note — $head → $base"

clean=0; wt=""
if [[ "$head" == agent/* ]] && [ "$cross" = false ]; then
  clean=1
  wt="$(git worktree list --porcelain | awk -v b="refs/heads/$head" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w}')"
  [ "$wt" != "$main_wt" ] || die "Nhánh '$head' đang checkout ở worktree chính ($main_wt) — checkout nhánh khác rồi chạy lại. Chưa đóng gì."
  [ "$wt" != "$repo_root" ] || die "Đang đứng TRONG worktree sẽ bị xoá ($wt) — chạy lại từ worktree chính ($main_wt). Chưa đóng gì."
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
  ref="$(tr '[:upper:]' '[:lower:]' <<<"$ref")"; repo="${ref%#*}"; n="${ref#*#}"
  st="$(gh issue view "$n" -R "$repo" --json state -q .state)"
  if [ "$repo" = "$this_repo" ]; then
    if ! git ls-tree -r --name-only "origin/$base" -- acceptance/ | grep -qE "^acceptance/$n-[^/]*\.sh$"; then
      echo "  ✗ #$n đóng mà KHÔNG có acceptance/$n-*.sh trên origin/$base"
      [ "$st" = CLOSED ] && run gh issue reopen "$n" --comment "Mở lại: PR #$PR đóng Issue này nhưng không có đơn vị nghiệm thu acceptance/$n-*.sh (AGENT.md §4). Khai đơn vị + PR mới."
      continue
    fi
    closed_local="$closed_local $n"; closed_refs="$closed_refs $this_repo#$n"
  else
    echo "  · $ref ở repo khác — đơn vị nghiệm thu thuộc repo đó (MULTI-REPO.md)"
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
  children="$(printf '%s\n%s\n' "$subs" "$tasks" | tr '[:upper:]' '[:lower:]' | grep -E '^[[:alnum:]_.-]+/[[:alnum:]_.-]+#[0-9]+$' | sort -u || true)"
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
    mk_tmp "origin/$base" || { echo "  ✗ Epic #$epic: không dựng được worktree tạm — chưa đóng (không phải nghiệm thu đỏ)"; continue; }
    erc=0; in_tmp env PR_BODY= ACCEPTANCE_DIR="$unit_dir" ./scripts/check.sh --acceptance >/dev/null || erc=$?; drop_tmp
    [ "$erc" -eq 0 ] || { echo "  ✗ Epic #$epic: mọi con đã đóng nhưng $unit_dir ĐỎ trên origin/$base — chưa đóng"; continue; }
    echo "  ✓ $unit_dir XANH (origin/$base)"
  fi
  run gh issue close "$epic" --comment "Mọi Issue con đã đóng (cuối cùng: PR #$PR) và nghiệm thu của epic XANH (post-merge.sh)."
done

# ── 2b. Plan → Epic/Story (thay cho workflow CI) ─────────────────────────────
echo; echo "2b. Plan (docs/superpowers/plans/) PR này thêm/sửa"
plans="$(grep -E '^docs/superpowers/plans/[^/]+\.md$' <<<"$pr_files" || true)"
# Project đã bật workflow plan-to-issues.yml (trigger push) thì bỏ bước này — 2 nơi cùng raise đua nhau tạo trùng.
# Tự nhận biết từ chính commit merge (khối `push:` không bị comment), không trông vào người vận hành nhớ đặt biến;
# PLANS_VIA_CI=1 vẫn ép bỏ qua được.
wf=.github/workflows/plan-to-issues.yml
if [ "${PLANS_VIA_CI:-}" = 1 ] || git show "$merge_sha:$wf" 2>/dev/null | grep -qE '^[[:space:]]+push:'; then
  [ -z "$plans" ] || echo "  · plan do workflow CI raise ($wf có trigger push, hoặc PLANS_VIA_CI=1) — bỏ qua bước này"
  plans=""
fi
plan_fail=""
[ -n "$plans" ] || echo "  (không có)"
# Đọc danh sách từ fd 3: lệnh con (python, gh) thừa hưởng stdin sẽ không nuốt mất dòng plan kế tiếp.
while IFS= read -r plan <&3; do
  [ -n "$plan" ] || continue
  git cat-file -e "$merge_sha:$plan" 2>/dev/null || { echo "  · $plan đã bị xoá trong PR — bỏ qua"; continue; }
  flag=(); [ "$DRY" -eq 1 ] && flag=(--dry-run)
  # PLAN_TO_ISSUES_REPO_ROOT: worktree tạm có đường dẫn khác ⇒ check-pin phải so với repo THẬT.
  if ! mk_tmp "$merge_sha"; then echo "  ✗ $plan: không dựng được worktree tạm — chưa raise"; plan_fail="$plan_fail $plan"; continue; fi
  prc=0; in_tmp env PLAN_TO_ISSUES_REPO_ROOT="$repo_root" python3 scripts/plan-to-issues.py "$plan" ${flag[@]+"${flag[@]}"} </dev/null || prc=$?; drop_tmp
  [ "$prc" -eq 0 ] || { echo "  ✗ $plan: plan-to-issues ĐỎ — không chặn bước dọn, nhưng script sẽ thoát mã 1"; plan_fail="$plan_fail $plan"; }
done 3<<<"$plans"

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
[ -z "$plan_fail" ] || { echo; echo "✗ Đóng vòng PR #$PR xong NHƯNG plan ĐỎ:$plan_fail — sửa plan qua PR mới (GIT-FLOW.md § \"Plan → Epic/Story\")." >&2; exit 1; }
echo; echo "✓ Đóng vòng PR #$PR xong. Còn lại: cập nhật HANDOFF.md (AGENT.md §7 bước 8)."
