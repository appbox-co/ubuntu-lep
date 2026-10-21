# ubuntu-lep 1.13.7-1 ("Nginx & PHP7.2 [Deprecated]"): the deployed ubuntu-lep
# image (Ubuntu 18.04, nginx + php-fpm7.2 7.2.5, built 2018-06-08) with its
# php7.2 packages replaced by Ubuntu 18.04's last public php7.2 source package
# (7.2.24-0ubuntu0.18.04.17) rebuilt with the local patches in
# php72-patches/. Nginx, supervisor, the entrypoint, the default
# configuration and the PHP branch are unchanged.
#
# The php72-build stage is copied verbatim from CyloTech/rutorrent-app branch
# php72-multipart-fix (the same patches and the same build arguments give the
# same BuildKit cache). release/sync-php72-stage.sh <rutorrent-app commit>
# refreshes it and php72-patches/ from a later commit of that branch.

# --- php72-build stage from CyloTech/rutorrent-app e5de63e2fa9b74bdbfdf81a69fa47d3c3af0a4f9 (local suffix +cylo2) ---
ARG PHP72_SOURCE_VERSION=7.2.24-0ubuntu0.18.04.17
ARG PHP72_LOCAL_SUFFIX=+cylo2

FROM ubuntu:18.04@sha256:152dc042452c496007f07ca9127571cb9c29697f42acbfad72324b2bb2e43c98 AS php72-build
ARG PHP72_SOURCE_VERSION
ARG PHP72_LOCAL_SUFFIX
ENV DEBIAN_FRONTEND=noninteractive DEBFULLNAME="Appbox build" DEBEMAIL=build@localhost

RUN sed -i 's/^# deb-src/deb-src/' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential devscripts dpkg-dev fakeroot quilt \
    && apt-get build-dep -y "php7.2=${PHP72_SOURCE_VERSION}"

WORKDIR /build
RUN apt-get source --only-source "php7.2=${PHP72_SOURCE_VERSION}"
COPY php72-patches/ /build/php72-patches/

# Append each local patch to the package's quilt series and fail the build
# if any of them does not apply cleanly.
RUN cd php7.2-7.2.24 \
    && export QUILT_PATCHES=debian/patches \
    && for patch in /build/php72-patches/*.patch; do \
           [ -e "$patch" ] || continue; \
           cp "$patch" debian/patches/; \
           basename "$patch" >> debian/patches/series; \
           quilt push "$(basename "$patch")"; \
       done \
    && dch --newversion "${PHP72_SOURCE_VERSION}${PHP72_LOCAL_SUFFIX}" --distribution bionic-security \
           "Appbox: apply local security patches from php72-patches/." \
    && DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" dpkg-buildpackage -b -uc -us
# --- end of php72-build stage ---

FROM repo.cylo.net/ubuntu-lep@sha256:bf9d02be675f92934acbbc976632e5f8336fdedcfabc000bc512b4c4a94a11fb
ARG PHP72_SOURCE_VERSION
ARG PHP72_LOCAL_SUFFIX
LABEL net.cylo.php-source-package="php7.2" \
      net.cylo.php-min-version="${PHP72_SOURCE_VERSION}${PHP72_LOCAL_SUFFIX}"

# Replace exactly the php7.2 packages the deployed image has installed with
# the rebuilt ones, and record which local patches they contain in
# /usr/share/cylo/php-local-patches (the release gate requires at least one).
RUN --mount=type=bind,from=php72-build,source=/build,target=/tmp/php72 \
    set -eu; \
    export DEBIAN_FRONTEND=noninteractive; \
    version="${PHP72_SOURCE_VERSION}${PHP72_LOCAL_SUFFIX}"; \
    pkgs=$(dpkg-query -W -f='${db:Status-Abbrev}|${binary:Package}|${source:Package}\n' \
        | awk -F'|' '$1 ~ /^ii/ && $3 == "php7.2" {print $2}'); \
    [ -n "$pkgs" ]; \
    debs=""; \
    for pkg in $pkgs; do \
        deb="/tmp/php72/${pkg}_${version}_amd64.deb"; \
        [ -f "$deb" ] || { echo "no rebuilt package for $pkg: $deb" >&2; exit 1; }; \
        debs="$debs $deb"; \
    done; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold $debs; \
    for pkg in $pkgs; do \
        [ "$(dpkg-query -W -f='${Version}' "$pkg")" = "$version" ] \
            || { echo "$pkg is not $version" >&2; exit 1; }; \
    done; \
    mkdir -p /usr/share/cylo; \
    for patch in /tmp/php72/php72-patches/*.patch; do \
        if [ -e "$patch" ]; then sha256sum "$patch" | sed 's#/tmp/php72/php72-patches/##'; fi; \
    done > /usr/share/cylo/php-local-patches; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    php-fpm7.2 -t
