#!/bin/bash
# Bundler clones cached git gems in parallel. On GitHub runners that races
# and Git exits with "hardlink different from source" or "failed to copy file".
# Serialize clone/fetch and copy objects instead of hardlinking.
# Bundler does not retry the local copy_to clone, so a failed clone is removed and tried again.
set -euo pipefail

dest="${RUNNER_TEMP}/bin"
lock="${RUNNER_TEMP}/bundler-git.lock"
mkdir -p "$dest"
touch "$lock"

cat > "$dest/git" << EOF
#!/bin/bash
if [ "\$1" = "clone" ]; then
  shift
  dest="\${@: -1}"
  attempt=1
  status=1
  while [ "\$attempt" -le 3 ]; do
    if /usr/bin/flock ${lock} /usr/bin/git clone --no-hardlinks "\$@"; then
      exit 0
    fi
    status=\$?
    if [ -n "\$dest" ] && [ -e "\$dest" ]; then
      rm -rf "\$dest"
    fi
    attempt=\$((attempt + 1))
    sleep 1
  done
  exit "\$status"
fi
if [ "\$1" = "fetch" ]; then
  exec /usr/bin/flock ${lock} /usr/bin/git "\$@"
fi
exec /usr/bin/git "\$@"
EOF
chmod +x "$dest/git"
echo "$dest" >> "$GITHUB_PATH"
