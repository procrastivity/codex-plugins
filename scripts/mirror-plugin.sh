#!/usr/bin/env bash
# mirror-plugin.sh — fetch a plugin's Codex slice from its source repo tag
# and drop it into plugins/<plugin>/ so this marketplace can serve it.
#
# Usage: mirror-plugin.sh <plugin> <source-repo> <ref>
#   plugin        Subdirectory name under plugins/ (usually matches the repo)
#   source-repo   GitHub owner/name of the source repo
#   ref           Tag or branch to clone (e.g. 'direnv-session-loader--v0.2.0')
#
# On success: plugins/<plugin>/ contains only the Codex-relevant paths,
# rebuilt from a shallow clone of the source ref. On failure (missing
# required path): exits non-zero without touching plugins/<plugin>/, so
# a bad mirror can never overwrite a good one.

set -Eeuo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $(basename "$0") <plugin> <source-repo> <ref>" >&2
  exit 2
fi

PLUGIN="$1"
SOURCE_REPO="$2"
REF="$3"

DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$DIR/.." && pwd)

# Paths inside the source repo that MUST exist. If any is missing, refuse
# to mirror — the tagged version doesn't include the Codex slice yet.
REQUIRED_PATHS=(
  ".codex-plugin"
  "hooks/codex"
  "scripts/codex"
  "scripts/lib"
  "LICENSE"
)
# Paths inside the source repo that we mirror when present but tolerate
# missing.
OPTIONAL_PATHS=(
  "README.md"
)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Cloning ${SOURCE_REPO}@${REF}..."
git clone --depth 1 --branch "$REF" \
  "https://github.com/${SOURCE_REPO}.git" "$tmp/src" >/dev/null

for p in "${REQUIRED_PATHS[@]}"; do
  if [ ! -e "$tmp/src/$p" ]; then
    echo "error: source ${SOURCE_REPO}@${REF} is missing required path: $p" >&2
    exit 1
  fi
done

target="$REPO_ROOT/plugins/$PLUGIN"
staging="$tmp/staging"
mkdir -p "$staging"

for p in "${REQUIRED_PATHS[@]}" "${OPTIONAL_PATHS[@]}"; do
  if [ -e "$tmp/src/$p" ]; then
    mkdir -p "$(dirname "$staging/$p")"
    cp -R "$tmp/src/$p" "$staging/$p"
  fi
done

rm -rf "$target"
mkdir -p "$(dirname "$target")"
mv "$staging" "$target"

src_sha=$(git -C "$tmp/src" rev-parse HEAD)
echo "Mirrored ${PLUGIN} from ${SOURCE_REPO}@${REF} (source SHA ${src_sha})"
echo "$src_sha"  # last stdout line is the SHA, for workflow commit messages
