# Regression checks

Each `*.sh` file here runs inside the candidate image during the release gate
(probe.sh runs `sh /gate/regression/<name>.sh` with this release directory
mounted read-only at both `/gate` and `/release`). It must exit 0 only when
the issue it covers is fixed. `lib/` holds shared helpers and is not run
directly.

The checks and `lib/` are copied from CyloTech/rutorrent-app branch
php72-multipart-fix (e5de63e2). `lib/fpm.sh` differs in one place: this image
has no `nginx` user, so the private php-fpm7.2 pool runs as `www-data` when
`nginx` does not exist.

| Check | Patch |
| --- | --- |
| `cve-2026-109618-oom.sh` | `0001-CVE-2026-109618-109619.patch` (out-of-memory handling, multipart headers) |
| `cve-2026-109619-state.sh` | `0001-CVE-2026-109618-109619.patch` (state reset, session upload progress) |
