#!/bin/bash
# Bundler clones cached git gems in parallel. On GitHub runners that races
# and Git exits with "hardlink different from source" or "failed to copy file".
# Serialize clone/fetch and copy objects instead of hardlinking.
# A failed clone must keep Git's exit status. Bundler does not retry copy_to,
# and treating the failure as success makes the next step stat a missing path.
set -euo pipefail

dest="${RUNNER_TEMP}/bin"
lock="${RUNNER_TEMP}/bundler-git.lock"
mkdir -p "$dest"
touch "$lock"

cat > "$dest/git" << EOF
#!/bin/bash
lock="${lock}"
if [ "\$1" = "clone" ]; then
  shift
  dest="\${@: -1}"
  exec 9>"\$lock"
  /usr/bin/flock 9
  if [ -e "\$dest/.git" ] || [ -f "\$dest/HEAD" ]; then
    exit 0
  fi
  attempt=1
  status=1
  while [ "\$attempt" -le 3 ]; do
    /usr/bin/git clone --no-hardlinks "\$@"
    status=\$?
    if [ "\$status" -eq 0 ]; then
      exit 0
    fi
    if [ -n "\$dest" ] && [ -e "\$dest" ]; then
      rm -rf "\$dest"
    fi
    attempt=\$((attempt + 1))
    sleep 1
  done
  echo "git-wrapper: clone failed (\$status)" >&2
  exit "\$status"
fi
if [ "\$1" = "fetch" ]; then
  exec /usr/bin/flock "\$lock" /usr/bin/git "\$@"
fi
exec /usr/bin/git "\$@"
EOF
chmod +x "$dest/git"
echo "$dest" >> "$GITHUB_PATH"
