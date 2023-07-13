#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2022, 2023 Olaf Meeuwissen

test -n "${DEBUG+true}" && set -x

DEVUAN_CODENAME=${1:-chimaera}
TARGET=${2:-_targets}/$DEVUAN_CODENAME
DEVUAN_DEB_REPO=http://deb.devuan.org/merged

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

# Check we are dealing with the expected Devuan environment.  Do this
# in a subshell to prevent needless pollution of the environment.

(. /etc/os-release
 test "$ID" = devuan || exit 1
 if test -n "${VERSION_CODENAME:-}"; then
     case "$VERSION_CODENAME" in
         $DEVUAN_CODENAME)    : ;;
         $DEVUAN_CODENAME\ *) : ;;
         *\ $DEVUAN_CODENAME) : ;;
         *) exit 1 ;;
     esac
 else                           # ascii doesn't set VERSION_CODENAME
     case "$PRETTY_NAME" in
         *\ $DEVUAN_CODENAME) : ;;
         *) exit 1 ;;
     esac
 fi)

# Install any missing requirements.  Anything that is installed here
# will be removed again after the root filesystem has been created.

REQUIREMENTS=""
command -v debootstrap > /dev/null \
    || REQUIREMENTS="$REQUIREMENTS debootstrap"

if test -n "$REQUIREMENTS"; then
    apt-mark showauto > /tmp/apt-mark.auto
    test -s /tmp/apt-mark.auto \
         && apt-mark manual $(cat /tmp/apt-mark.auto) > /dev/null
    apt-get --quiet update
    apt-get --quiet install $REQUIREMENTS \
            --assume-yes --no-install-recommends
fi

# Provision the expected keyring so the package archive's InRelease
# file can be verified.  This establishes the chain of trust for all
# packages that are going to be installed in the root filesystem.

KEYRING_FILE=$(sed -n 's/^keyring[ \t]*//p' \
                   "/usr/share/debootstrap/scripts/$DEVUAN_CODENAME")

test -f "$KEYRING_FILE" && mv "$KEYRING_FILE" "$KEYRING_FILE.bak"
case "$DEVUAN_CODENAME" in
    excalibur)
        cp "/etc/apt/trusted.gpg.d/devuan-keyring-$DEVUAN_CODENAME-archive.gpg" \
           "$KEYRING_FILE"
        ;;
    *)
        cp /etc/apt/trusted.gpg.d/devuan-keyring-2016-archive.gpg \
           "$KEYRING_FILE"
        ;;
esac

# Create a Devuan root filesystem

mkdir -p "$TARGET"
mkdir -p "$PWD/_caches/apt/archives"

# Packages related to booting and running PID 1 are pointless for
# container images in most use cases.  Explicitly exclude the few
# that are known to get included otherwise.

DEBOOTSTRAP_OPTS=
if debootstrap --help | grep -q -- --cache-dir=; then
    DEBOOTSTRAP_OPTS="--cache-dir=$PWD/_caches/apt/archives"
fi

debootstrap \
    --exclude=bootlogd,initscripts,sysv-rc,sysvinit-core \
    $DEBOOTSTRAP_OPTS \
    --variant=minbase \
    --components=main \
    "$DEVUAN_CODENAME" "$TARGET" $DEVUAN_DEB_REPO

# Restore the system's original keyring file if we replaced it.

test -f "$KEYRING_FILE.bak" && mv "$KEYRING_FILE.bak" "$KEYRING_FILE"

# Add security and updates suites, insofar these are available.
#
# This relies on curl to relay the HTTP status code of the responses
# we get to determine presence of suites.  If not available, curl is
# installed temporarily, in such a way that it (and any dependencies
# it pulls in) can be uninstalled again when its job is done.
# Note that curl is *not* installed in the debootstrap'd $TARGET but
# in the system running this script.

command -v curl > /dev/null \
    || REQUIREMENTS="$REQUIREMENTS curl"

if test -n "$REQUIREMENTS"; then
    test -f /tmp/apt-mark.auto \
        || apt-mark showauto > /tmp/apt-mark.auto
    test -s /tmp/apt-mark.auto \
        && apt-mark manual $(cat /tmp/apt-mark.auto) > /dev/null
    apt-get --quiet update
    apt-get --quiet install $REQUIREMENTS \
            --assume-yes --no-install-recommends
fi

for suite in "-security" "-updates"; do
    code=$(curl --silent --location --show-error --head \
                --output /dev/null --write-out "%{http_code}" \
                $DEVUAN_DEB_REPO/dists/$DEVUAN_CODENAME$suite/InRelease)

    case "$code" in
        200)
            echo >&2 "adding $DEVUAN_CODENAME$suite"
            sed -n "s/ $DEVUAN_CODENAME / $DEVUAN_CODENAME$suite /p" \
                "$TARGET/etc/apt/sources.list" >> "$TARGET/etc/apt/sources.list"
            ;;
        404)
            if test -n "$suite"; then
                echo >&2 "skipping $DEVUAN_CODENAME$suite ($code)"
            else
                echo >&2 "$DEVUAN_CODENAME$suite: Not Found ($code)!"
                exit 1
            fi
            ;;
        *)
            echo >&2 "ignoring $DEVUAN_CODENAME$suite ($code)"
            ;;
    esac
done

# Uninstall any requirements that were installed in the system running
# this script on a temporary basis.

if test -n "$REQUIREMENTS"; then
    apt-get --quiet purge $REQUIREMENTS \
            --assume-yes --auto-remove
    test -s /tmp/apt-mark.auto \
         && apt-mark auto $(cat /tmp/apt-mark.auto) > /dev/null
fi

# Apply any available security and other updates to the chroot.

chroot $TARGET apt-get --quiet update
chroot $TARGET apt-get --quiet upgrade --assume-yes

# Mark all packages as automatically installed so that they can become
# candidates for auto-removal.  Make sure to keep our keyring package.
# This generates a /var/lib/apt/extended_states file as a side-effect.

chroot $TARGET sh -c "dpkg-query -W -f '\${Package}\n' | xargs apt-mark auto"
chroot $TARGET apt-mark manual devuan-keyring

# Clean out the root filesystem to prevent the most egregrious,
# unneeded disk hogs.  Note that the shell glob expansion needs
# to be done *inside* the chroot.

chroot $TARGET apt-get clean
chroot $TARGET sh -c 'rm /var/lib/apt/lists/*_dists_*'
