#!/bin/bash
# Bundler clones cached git gems in parallel. On GitHub runners that races
# and Git exits with "hardlink different from source" or "failed to copy file".
# Serialize clone/fetch and copy objects instead of hardlinking.
set -euo pipefail

dest="${RUNNER_TEMP}/bin"
lock="${RUNNER_TEMP}/bundler-git.lock"
mkdir -p "$dest"
touch "$lock"

cat > "$dest/git" << EOF
#!/bin/bash
if [ "\$1" = "clone" ]; then
  shift
  exec /usr/bin/flock ${lock} /usr/bin/git clone --no-hardlinks "\$@"
fi
if [ "\$1" = "fetch" ]; then
  exec /usr/bin/flock ${lock} /usr/bin/git "\$@"
fi
exec /usr/bin/git "\$@"
EOF
chmod +x "$dest/git"
echo "$dest" >> "$GITHUB_PATH"
