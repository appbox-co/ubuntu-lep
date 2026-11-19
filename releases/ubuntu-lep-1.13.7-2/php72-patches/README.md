# php7.2 patches

Each `*.patch` file here is added to Ubuntu's php7.2 quilt series in name
order, so prefix them with a number (`0001-...`). Patches must apply to the
`php7.2-7.2.24` source tree with `-p1`; the build fails if one does not.

Bump `PHP72_LOCAL_SUFFIX` in the Dockerfile (`+cylo1`, `+cylo2`, ...) whenever
the set of patches changes, and add a regression check under
`release/regression/` for the issue each patch fixes. `+cylo1` was the
rebuild without patches (9f3b937); `+cylo2` adds `0001`; `+cylo3` adds `0002`.

The build is checked against two recorded package lists, so update them with
the suffix:

- `release/php72-build-packages.txt`: the packages in the build stage after
  `apt-get build-dep`. The build stops if apt installs anything else.
- `release/expected-packages.txt`: every package in the final image. The
  release gate compares it, and requires `expected_php72_version` in
  `release/verify-image.sh` for php-fpm7.2 and every php7.2 package.

## Patches

- `0001-CVE-2026-109618-109619.patch`: PHP 7.2 port of php-src's minimal
  mitigation for CVE-2026-109618 and CVE-2026-109619 (Canonical's php8.1
  8.1.2-1ubuntu2.28 patch, php-src 1d7dec178a0). The patch header maps each
  8.1 hunk to 7.2. Behaviour changes: memory exhaustion ends the PHP process
  (an FPM worker exits with status 1, the client gets no response, and
  shutdown functions do not run; the message is in the FPM log), and
  `session.upload_progress.enabled` no longer has any effect.
- `0002-CVE-2026-11-19-php-src.patch`: PHP 7.2 port of the php-src security
  fixes released on 19 November 2026 with 8.2.36/8.3.37/8.4.28/8.5.13 that
  apply to 7.2: FPM request smuggling through an unread body
  (CVE-2026-129289), session files truncated before every write
  (CVE-2026-126714), UTC error-log timestamps outside an active request
  (CVE-2026-129496), TLS chosen from the whole HTTPS/FTPS scheme
  (CVE-2026-128064), keyless phar signatures refused when a .pubkey exists
  (CVE-2026-128090), the CGI PATH_INFO underflow (CVE-2026-129538) and two
  SOAP fixes (CVE-2026-15353, CVE-2026-129506). The patch header maps each
  hunk to its upstream PHP-8.2 commit and lists what was left out and why.
  Behaviour change: none beyond the fixes; a session write now fails with a
  warning if the file cannot be truncated.
