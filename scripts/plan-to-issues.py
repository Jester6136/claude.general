#!/usr/bin/env python3
"""plan-to-issues.py <plan.md> [--dry-run] — biến MỘT plan của superpowers:writing-plans thành 1 Epic + N Story.

Định dạng plan bám đúng bản ĐÃ CÀI và ĐÃ GHIM (không bám nhánh main trên GitHub):
    PINNED_PLUGIN @ PINNED_VERSION (bên dưới — nguồn duy nhất của số phiên bản) — skills/writing-plans/SKILL.md
Plan khác định dạng ⇒ TỪ CHỐI và liệt kê chỗ sai, không đoán. Plugin đổi phiên bản ⇒ đối chiếu lại
SKILL.md, cập nhật PINNED_* bên dưới, chạy lại bộ kiểm (GIT-FLOW.md § "Plan → Epic/Story").

Ánh xạ (tất định — cùng plan@commit + cùng trạng thái Issue ⇒ cùng kết quả):
  plan                    → 1 Issue nhãn `epic`: link plan@SHA, Goal, task-list `- [ ] #N` của các story
  `### Task N: <tên>`     → 1 Issue nhãn `agent-ready`, đúng các mục của .github/ISSUE_TEMPLATE/agent-ready.yml:
      Yêu cầu             = nguyên văn khối Task N (trích, không diễn giải) + link plan@SHA
      Vị trí file         = các dòng của **Files:**
      Cấp nghiệm thu      = N0 (task của writing-plans tự chứng minh bằng lệnh test) — đổi tay nếu task chạm
                            thứ không tất định (AGENT.md §4.1)
      Đơn vị nghiệm thu   = mọi cặp `Run:`/`Expected:` của task: Expected chứa FAIL = phải ĐỎ trên nhánh nền,
                            Expected chứa PASS = phán quyết XANH. Task KHÔNG có cặp PASS ⇒ plan bị từ chối.
      Epic                = #<epic>
      Blocked by          = Issue của các "Task k" được nhắc trong dòng `- Consumes:` của **Interfaces:**
  Story được link vào epic hai đường: sub-issue (API) + dòng task-list trong body epic (post-merge.sh đọc cả hai).

Chạy lại an toàn: mỗi Issue mang marker ẩn `<!-- plan-to-issues: plan=<path> task=<N|epic> -->`; Issue đã có
thì bỏ qua (không sửa); body epic chỉ được NỐI thêm dòng story còn thiếu, không viết lại. Plan đã raise mà
cần đổi thì sửa Issue tay hoặc viết plan mới. Plan đã raise KHÔNG được đổi tên/di chuyển (marker theo path —
workflow từ chối rename).
"""
import json
import os
import re
import subprocess
import sys

PINNED_PLUGIN = "superpowers@anthropic-plugin-directory"
PINNED_VERSION = "7.0.2-22f0b463e7a5"
MARK = "<!-- plan-to-issues: plan={path} task={task} -->"
INSTALLED = os.path.expanduser("~/.claude/plugins/installed_plugins.json")


def check_pin():
    """`.claude/settings.json` chỉ BẬT plugin, KHÔNG ghim phiên bản — bản cài nằm ở user-level
    (~/.claude/plugins/installed_plugins.json). Nên ghim được ép ở đây: máy có cài mà lệch PINNED_VERSION ⇒
    từ chối (plan có thể theo định dạng khác). Máy không cài (CI) ⇒ chỉ áp định dạng của PINNED_VERSION."""
    try:
        entries = json.load(open(INSTALLED)).get("plugins", {}).get(PINNED_PLUGIN, [])
    except FileNotFoundError:
        return f"(máy này không cài {PINNED_PLUGIN} — chỉ kiểm định dạng theo {PINNED_VERSION})"
    versions = sorted({e.get("version") for e in entries})
    if versions != [PINNED_VERSION]:
        sys.exit(f"✗ {PINNED_PLUGIN} đang cài {versions or 'KHÔNG CÓ'} ≠ ghim {PINNED_VERSION}. Cài đúng bản ghim, "
                 f"hoặc nâng ghim có chủ đích (GIT-FLOW.md § \"Plan → Epic/Story\").")
    return f"✓ {PINNED_PLUGIN} đã cài đúng bản ghim {PINNED_VERSION}"


def sh(*args, check=True):
    r = subprocess.run(args, capture_output=True, text=True)
    if check and r.returncode != 0:
        sys.exit(f"✗ lệnh lỗi: {' '.join(args)}\n{r.stderr.strip()}")
    return r.stdout


def _heading_end(rest):
    """Vị trí heading cấp ≤3 kế tiếp NGOÀI code fence (vd '## Self-Review') — khối task dừng ở đó.
    `# comment` trong ```bash/```python không phải heading."""
    pos, fence = 0, False
    for line in rest.splitlines(keepends=True):
        if line.lstrip().startswith("```"):
            fence = not fence
        elif not fence and re.match(r"#{1,3} ", line):
            return pos
        pos += len(line)
    return len(rest)


def parse(text):
    """Trả (plan, errors). Không đoán: thiếu gì ghi vào errors."""
    errors = []
    m = re.search(r"^# (.+?) Implementation Plan\s*$", text, re.M)
    feature = m.group(1).strip() if m else None
    if not feature:
        errors.append("thiếu H1 '# <Feature> Implementation Plan'")
    goal = re.search(r"^\*\*Goal:\*\*\s*(.+)$", text, re.M)
    if not goal:
        errors.append("thiếu dòng '**Goal:** …'")
    heads = list(re.finditer(r"^### Task (\d+): (.+?)\s*$", text, re.M))
    if not heads:
        errors.append("không có '### Task N: <tên>' nào")
    tasks = []
    for i, h in enumerate(heads):
        n, name = int(h.group(1)), h.group(2).strip()
        end = heads[i + 1].start() if i + 1 < len(heads) else len(text)
        block = text[h.start(): h.end() + _heading_end(text[h.end():end])]
        if n != i + 1:
            errors.append(f"Task {n}: số thứ tự không liên tục (mong đợi {i + 1})")
        files = re.search(r"^\*\*Files:\*\*\s*\n((?:- .+\n?)+)", block, re.M)
        if not files:
            errors.append(f"Task {n}: thiếu khối '**Files:**'")
        runs = re.findall(r"^Run:\s*`([^`]+)`\s*\nExpected:\s*(.+)$", block, re.M)
        passes = [(c, e) for c, e in runs if "PASS" in e]
        fails = [(c, e) for c, e in runs if "FAIL" in e]
        if not passes:
            errors.append(f"Task {n}: không có cặp 'Run:'/'Expected: … PASS' — task không có đơn vị nghiệm thu")
        consumes = re.search(r"^- Consumes:\s*(.+(?:\n  .+)*)", block, re.M)
        deps = sorted({int(k) for k in re.findall(r"\bTask (\d+)\b", consumes.group(1))} - {n}) if consumes else []
        bad = [k for k in deps if not 1 <= k < n]
        if bad:
            errors.append(f"Task {n}: 'Consumes:' trỏ Task {bad} — chỉ được phụ thuộc task ĐỨNG TRƯỚC (1..{n - 1})")
        # Hạ cấp heading trong khối trích (### → ####) để không chen vào các mục ### của issue form;
        # chữ giữ nguyên văn. Dòng trong code fence không đụng tới.
        quoted, fence = [], False
        for line in block.strip().splitlines():
            if line.lstrip().startswith("```"):
                fence = not fence
            quoted.append("#" + line if (not fence and re.match(r"^#{1,5} ", line)) else line)
        tasks.append(dict(n=n, name=name, block="\n".join(quoted), deps=deps,
                          files=[l[2:].strip() for l in files.group(1).strip().splitlines()] if files else [],
                          passes=passes, fails=fails))
    return dict(feature=feature, goal=goal.group(1).strip() if goal else None, tasks=tasks), errors


def acceptance_md(t):
    lines = []
    for c, e in t["fails"]:
        lines.append(f"- Trên nhánh nền phải ĐỎ: `{c}` → {e.strip()}")
    for c, e in t["passes"]:
        lines.append(f"- Phán quyết XANH: `{c}` → {e.strip()}")
    lines.append(f"- Khai thành `acceptance/<số Issue này>-<slug>.sh` chạy đúng (các) lệnh PASS ở trên "
                 f"(AGENT.md §7 bước 2).")
    return "\n".join(lines)


def story_body(plan, t, path, url, epic_no, issue_of):
    blocked = ", ".join(f"#{issue_of.get(k, f'<Task {k}>')}" for k in t["deps"]) or "—"
    return f"""{MARK.format(path=path, task=t['n'])}
### Yêu cầu (trích nguyên văn từ tài liệu nguồn)

Nguồn: [{path} — Task {t['n']}]({url}) (sinh bởi `scripts/plan-to-issues.py`, plan viết bằng {PINNED_PLUGIN} {PINNED_VERSION})

{t['block']}

### Vị trí file dự kiến chạm

{", ".join(t['files'])}

### Cấp nghiệm thu (AGENT.md §4.1)

N0 — core/platform: fake/stub thay thứ không tất định, assert chính xác
(mặc định cho task của writing-plans; đổi nếu task chạm LLM/mạng/thứ không tất định)

### Đơn vị nghiệm thu — lệnh + kết quả/ngưỡng mong đợi (KHAI TRƯỚC khi code)

{acceptance_md(t)}

### Phạm vi KHÔNG được đụng vào

File ngoài danh sách ở trên; phần việc của các Task khác trong cùng plan; mục "Global Constraints" của plan.

### Epic (nếu Issue này là một phần của epic)

#{epic_no}

### Blocked by (Issue/PR nào phải xong trước, nếu có)

{blocked}
"""


def epic_body(plan, path, url, stories):
    tl = "\n".join(f"- [ ] #{no} Task {n}: {name}" for n, name, no in stories) or "- (chưa có story)"
    return f"""{MARK.format(path=path, task='epic')}
**Plan:** [{path}]({url}) — {PINNED_PLUGIN} {PINNED_VERSION}

**Goal:** {plan['goal']}

Epic đóng khi mọi story dưới đây đã đóng (mỗi story có phán quyết nghiệm thu tất định riêng) và
`acceptance/epic/<số epic>/` (nếu có) XANH — `scripts/post-merge.sh`, GIT-FLOW.md § "Sau merge — đóng vòng".

## Stories
{tl}
"""


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if "--check-pin" in sys.argv:
        print(check_pin())
        return
    if len(args) != 1:
        sys.exit("Dùng: scripts/plan-to-issues.py <plan.md> [--dry-run] | --check-pin")
    print(check_pin())
    path = args[0]
    if not sh("git", "ls-files", "--", path).strip():
        sys.exit(f"✗ {path} chưa được commit — Issue phải trỏ tới bản plan bất biến (plan@SHA)")
    if sh("git", "status", "--porcelain", "--", path).strip():
        sys.exit(f"✗ {path} còn thay đổi chưa commit — commit trước để link plan@SHA khớp nội dung")
    sha = sh("git", "log", "-1", "--format=%H", "--", path).strip()
    text = sh("git", "show", f"{sha}:{path}")
    plan, errors = parse(text)
    if errors:
        print(f"✗ {path} không đúng định dạng writing-plans ({PINNED_VERSION}) — KHÔNG tạo Issue nào:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        sys.exit(1)
    repo = sh("gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner").strip()
    url = f"https://github.com/{repo}/blob/{sha}/{path}"

    # Đọc ĐỦ mọi trang (không cắt ở N issue) — thiếu một trang là raise trùng epic/story.
    existing = [json.loads(l) for l in sh("gh", "api", "--paginate", f"repos/{repo}/issues?state=all&per_page=100",
                                           "--jq", ".[] | select(.pull_request == null) | {number, body}").splitlines() if l]
    def find(task):
        mk = MARK.format(path=path, task=task)
        hits = [i["number"] for i in existing if mk in (i["body"] or "")]
        return min(hits) if hits else None

    def create(title, body, label):
        if dry:
            return None
        out = sh("gh", "issue", "create", "--title", title, "--body", body, "--label", label)
        return int(out.strip().rsplit("/", 1)[-1])

    print(f"Plan: {path}@{sha[:7]} — '{plan['feature']}', {len(plan['tasks'])} task")
    if not dry:
        for lb, color in (("epic", "5319e7"), ("agent-ready", "0e8a16")):
            sh("gh", "label", "create", lb, "--color", color, check=False)  # đã có thì bỏ qua

    epic_no = find("epic")
    if epic_no:
        print(f"  ✓ epic đã có: #{epic_no}")
    else:
        epic_no = create(f"[Epic] {plan['feature']}", epic_body(plan, path, url, []), "epic")
        print(f"  {'[dry-run] sẽ tạo' if dry else '+ tạo'} epic: [Epic] {plan['feature']}" + (f" → #{epic_no}" if epic_no else ""))

    issue_of, stories = {}, []
    for t in plan["tasks"]:
        title = f"{plan['feature']}: Task {t['n']} — {t['name']}"
        no = find(t["n"])
        if no:
            print(f"  ✓ Task {t['n']} đã có: #{no}")
        else:
            no = create(title, story_body(plan, t, path, url, epic_no or "<epic>", issue_of), "agent-ready")
            deps = ", ".join(f"Task {k}" for k in t["deps"]) or "—"
            print(f"  {'[dry-run] sẽ tạo' if dry else '+ tạo'} story: {title} · PASS={len(t['passes'])} FAIL={len(t['fails'])} · Blocked by: {deps}"
                  + (f" → #{no}" if no else ""))
        if no:
            issue_of[t["n"]] = no
            stories.append((t["n"], t["name"], no))

    if dry or not epic_no:
        return
    # Link 2 đường: task-list trong body epic + sub-issue API (đã link thì API trả 422 — bỏ qua).
    # Body epic KHÔNG viết lại: chỉ NỐI dòng của story chưa có — giữ dấu [x], con thêm tay, ghi chú.
    body = sh("gh", "issue", "view", str(epic_no), "--json", "body", "-q", ".body")
    have = {int(x) for x in re.findall(r"^\s*[-*] \[[ xX]\] #(\d+)\b", body, re.M)}
    missing = [f"- [ ] #{no} Task {n}: {name}" for n, name, no in stories if no not in have]
    if missing:
        body = re.sub(r"\n- \(chưa có story\)\s*$", "", body.rstrip("\n")) + "\n" + "\n".join(missing) + "\n"
        sh("gh", "issue", "edit", str(epic_no), "--body", body)
    for _, _, no in stories:
        iid = sh("gh", "api", f"repos/{repo}/issues/{no}", "-q", ".id").strip()
        sh("gh", "api", "-X", "POST", f"repos/{repo}/issues/{epic_no}/sub_issues", "-F", f"sub_issue_id={iid}", check=False)
    print(f"  ✓ epic #{epic_no}: link {len(stories)} story (task-list + sub-issue)")


if __name__ == "__main__":
    main()
