# ubuntu-lep 1.13.7-1 (Nginx & PHP7.2 [Deprecated], app 75)

Security rebuild for the PHP release of 21 October 2026 (multipart/form-data
parsing fixes). The image is the deployed ubuntu-lep image, `repo.cylo.net/ubuntu-lep@sha256:bf9d02be675f92934acbbc976632e5f8336fdedcfabc000bc512b4c4a94a11fb` (Ubuntu 18.04, php7.2 7.2.5), with only the PHP packages
replaced; the PHP branch, web server, scripts and default configuration stay
as deployed. It is published as `repo.cylo.net/ubuntu-lep:1.13.7-1` (a new immutable tag).

## 1. Is the patched PHP available?

There is no public patched php7.2 for Ubuntu 18.04 (only Ubuntu Pro ESM).
The fix is a local backport shared with ruTorrent: it is ready when
CyloTech/rutorrent-app branch `php72-multipart-fix` has a commit that adds
`php72-patches/0001-*.patch` and a matching `release/regression/*.sh`:

```sh
git -C /Users/rid/Development/Current/rutorrent-app fetch -q origin php72-multipart-fix
git -C /Users/rid/Development/Current/rutorrent-app ls-tree --name-only origin/php72-multipart-fix php72-patches/ release/regression/
```

## 2-5. Pin, build, gate, push

```sh
cd <checkout of php-multipart-fix>          # e.g. git worktree add ... origin/php-multipart-fix
git pull --ff-only
releases/ubuntu-lep-1.13.7-1/release/sync-php72-stage.sh <rutorrent-app commit with the patch>
git add -A releases/ubuntu-lep-1.13.7-1
git commit -m "ubuntu-lep 1.13.7-1: php7.2 patches from rutorrent-app <commit>"
git push origin php-multipart-fix
releases/ubuntu-lep-1.13.7-1/release/builder-release.sh release
```

The php72-build stage, `php72-patches/0001-CVE-2026-109618-109619.patch`
(sha256 e47e252a8702d23dfee026948cc4a8979f119a9478a024e03d4903889f3fd4e7)
and the regression checks come from rutorrent-app e5de63e2; the local
version suffix is `+cylo2`, so every php7.2 package is
`7.2.24-0ubuntu0.18.04.17+cylo2`.

`builder-release.sh` refuses uncommitted or unpushed work, archives this
directory from the pushed commit, builds on builder1 (port 10112) with
`--no-cache --platform linux/amd64`, runs `release/verify-image.sh` and pushes only if
the gate passes, then prints the pushed digest. `builder-release.sh trial`
does the same as a local `local/<image>-trial:<tag>` image with the trial
build arguments in `release/gate.conf` and never pushes.

## The gate (release/verify-image.sh)

- the image is the base plus the overlay layers, with the same entrypoint,
  command, environment, ports and volumes, and (where set) base layers that
  hash to `GATE_BASE_LAYERS_SHA256`;
- every package built from the PHP source package was upgraded, to at least
  the pinned version, and newer than the last unpatched version; no other
  package was removed;
- CLI and FPM module lists, `php-fpm -t`, and every file under the packaged
  configuration and script directories match the base (only PHP's own ini
  defaults may change content);
- a multipart upload works through the CLI server;
- the deployed image and the candidate run like the platform runs them
  (init, the app's volumes): after an update the candidate serves the
  existing PHP site through its own web server and SAPI with the same
  modules, accepts a multipart upload, passes its config tests, and leaves the
  config volume exactly as recreating the deployed image does; a fresh install
  works too (and its database starts, where the app has one);
- `release/regression/*.sh` pass;
- the registry reports the tag absent (authenticated, fails closed).
