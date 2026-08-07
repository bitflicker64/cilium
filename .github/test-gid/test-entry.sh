#!/bin/bash
# Runs inside the Renovate container as root, like renovatebot/github-action
# does with docker-user: root. Reuses the real entrypoint but swaps the final
# "runuser -u ubuntu renovate" for assertions + a builder.sh smoke test.
set -euo pipefail

cd /repo

sed '$d' .github/actions/renovate/entrypoint.sh > /tmp/entry.sh

cat >> /tmp/entry.sh <<'EOF'
echo "=== ubuntu user after entrypoint group fix ==="
runuser -u ubuntu -- id
runuser -u ubuntu -- bash -ec '
  [ "$(id -u)" = 12021 ] || { echo "FAIL: uid is $(id -u), expected 12021"; exit 1; }
  [ "$(id -g)" = 12021 ] || { echo "FAIL: gid is $(id -g), expected 12021"; exit 1; }
  id -G | tr " " "\n" | grep -qx 0 || { echo "FAIL: root group not in supplementary groups"; exit 1; }
  echo "OK: running as 12021:12021 with root as supplementary group"
  cd /repo
  echo "=== builder.sh smoke test ==="
  V=1 contrib/scripts/builder.sh true
  echo "OK: builder.sh completed"
'
EOF

bash /tmp/entry.sh
