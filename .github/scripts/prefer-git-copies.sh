#!/bin/bash
# Bundler clones cached git gems with hardlinks. Parallel clones on GitHub
# runners fail with "fatal: hardlink different from source". Copy instead.
set -euo pipefail

dest="${RUNNER_TEMP}/bin"
mkdir -p "$dest"
cat > "$dest/git" << 'EOF'
#!/bin/bash
if [ "$1" = "clone" ]; then
  shift
  exec /usr/bin/git clone --no-hardlinks "$@"
fi
exec /usr/bin/git "$@"
EOF
chmod +x "$dest/git"
echo "$dest" >> "$GITHUB_PATH"
