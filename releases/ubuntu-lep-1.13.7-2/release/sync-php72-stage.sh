#!/bin/bash
# Copy the php72-build stage, php72-patches/ and the patch regression checks
# from a commit of CyloTech/rutorrent-app (branch php72-multipart-fix) into
# this release directory, so ubuntu-lep is built with exactly the same patched
# php7.2 as ruTorrent.
#
# Usage: release/sync-php72-stage.sh <rutorrent-app commit> [<rutorrent-app checkout>]
# The checkout defaults to /Users/rid/Development/Current/rutorrent-app; only
# `git fetch` and `git show` are run in it. Review and commit the result.
set -euo pipefail

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[ "$#" -ge 1 ] || fail "usage: $0 <rutorrent-app commit> [<checkout>]"
rt_commit=$1
rt_repo=${2:-/Users/rid/Development/Current/rutorrent-app}
case "$rt_commit" in *[!0-9a-f]*|'') fail "commit must be a hex SHA" ;; esac

release_dir=$(cd "$(dirname "$0")" && pwd)
context_dir=$(dirname "$release_dir")
dockerfile="$context_dir/Dockerfile"

git -C "$rt_repo" fetch -q origin php72-multipart-fix
rt_commit=$(git -C "$rt_repo" rev-parse --verify "$rt_commit^{commit}")
git -C "$rt_repo" merge-base --is-ancestor "$rt_commit" origin/php72-multipart-fix \
    || fail "$rt_commit is not on origin/php72-multipart-fix"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Everything in the ruTorrent Dockerfile from the first ARG up to the final
# ruTorrent stage is the php72-build stage.
git -C "$rt_repo" show "$rt_commit:Dockerfile" \
    | awk '/^FROM repo\.cylo\.net\/rutorrent/ {exit} started || /^ARG / {started = 1; print}' \
    | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$work/stage"
grep -q '^FROM .* AS php72-build$' "$work/stage" || fail "no php72-build stage in $rt_commit:Dockerfile"

awk -v stage="$work/stage" -v sha="$rt_commit" '
    /^# --- php72-build stage from / {
        print "# --- php72-build stage from CyloTech/rutorrent-app " sha " ---"
        while ((getline line < stage) > 0) print line
        skipping = 1
        next
    }
    /^# --- end of php72-build stage ---$/ {skipping = 0}
    !skipping {print}
' "$dockerfile" > "$work/Dockerfile"
grep -q "^# --- end of php72-build stage ---$" "$work/Dockerfile" || fail "stage markers missing in $dockerfile"
cp "$work/Dockerfile" "$dockerfile"

rm -rf "$context_dir/php72-patches"
mkdir -p "$context_dir/php72-patches"
git -C "$rt_repo" archive "$rt_commit" php72-patches | tar -x -C "$context_dir"

# Regression checks that come with the patches (ruTorrent's own README stays).
for check in $(git -C "$rt_repo" ls-tree --name-only "$rt_commit" release/regression/ | grep '\.sh$' || true); do
    git -C "$rt_repo" show "$rt_commit:$check" > "$release_dir/regression/$(basename "$check")"
done

echo "Synced the php72-build stage and php72-patches/ from rutorrent-app $rt_commit:"
ls -1 "$context_dir/php72-patches"
git -C "$context_dir" status --short -- "$context_dir"
