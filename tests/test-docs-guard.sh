#!/usr/bin/env bash
set -euo pipefail

fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

git -C "$fixture" init -q
git -C "$fixture" config user.email "test@example.com"
git -C "$fixture" config user.name "Test"
git -C "$fixture" config commit.gpgsign false
mkdir -p "$fixture/src" "$fixture/tests" "$fixture/scripts"
cp templates/docs-guard.sh "$fixture/scripts/docs-guard.sh"
chmod +x "$fixture/scripts/docs-guard.sh"
printf '# Changelog\n\n## [Unreleased]\n' > "$fixture/CHANGELOG.md"
printf 'base\n' > "$fixture/src/app.txt"
printf 'base test\n' > "$fixture/tests/app.test.txt"
git -C "$fixture" add .
git -C "$fixture" commit -qm base
git -C "$fixture" branch -M development
git -C "$fixture" checkout -qb feat/DWT-123-doc-policy

printf 'change\n' >> "$fixture/src/app.txt"
printf 'test change\n' >> "$fixture/tests/app.test.txt"
git -C "$fixture" add .
git -C "$fixture" commit -qm implementation
if (cd "$fixture" && BASE_BRANCH=development TICKET_ID=DWT-123 scripts/docs-guard.sh >/dev/null 2>&1); then
  echo "expected missing changelog to fail" >&2
  exit 1
fi

printf '\n### Changed\n\n- Updated policy. (DWT-123)\n' >> "$fixture/CHANGELOG.md"
git -C "$fixture" add CHANGELOG.md
git -C "$fixture" commit -qm plain-ticket
if (cd "$fixture" && BASE_BRANCH=development TICKET_ID=DWT-123 scripts/docs-guard.sh >/dev/null 2>&1); then
  echo "expected unlinked ticket to fail" >&2
  exit 1
fi

printf -- '- Linked policy. ([DWT-123](https://example.atlassian.net/browse/DWT-123))\n' >> "$fixture/CHANGELOG.md"
git -C "$fixture" add CHANGELOG.md
git -C "$fixture" commit -qm linked-ticket
(cd "$fixture" && BASE_BRANCH=development TICKET_ID=DWT-123 scripts/docs-guard.sh >/dev/null)

printf 'working tree change\n' >> "$fixture/src/app.txt"
printf 'working tree test\n' >> "$fixture/tests/app.test.txt"
printf -- '- Working tree policy. ([DWT-124](https://example.atlassian.net/browse/DWT-124))\n' >> "$fixture/CHANGELOG.md"
(cd "$fixture" && BASE_BRANCH=development TICKET_ID=DWT-124 scripts/docs-guard.sh >/dev/null)

echo "docs-guard tests: ok"
