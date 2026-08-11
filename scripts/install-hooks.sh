#!/usr/bin/env bash
# scripts/install-hooks.sh — cài git hooks cho repo hiện tại. Git KHÔNG version .git/hooks, nên mỗi
# người clone/agent phiên đầu phải tự chạy file này một lần (GIT-FLOW.md §11b "Phương án không cần quyền").
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
cp "$repo_root/scripts/hooks/pre-push" "$repo_root/.git/hooks/pre-push"
chmod +x "$repo_root/.git/hooks/pre-push"
echo "✓ Cài pre-push hook xong. Kiểm: git push --no-verify sẽ bỏ qua, push thường sẽ chạy cổng tĩnh."
