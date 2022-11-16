#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2022 Olaf Meeuwissen

test -n "${DEBUG+true}" && set -x

DEVUAN_CODENAME=${1:-chimaera}
ROOTFS_LOCATION=${2:-rootfs}/$DEVUAN_CODENAME

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

# Check we are dealing with the expected Devuan environment.  Do this
# in a subshell to prevent needless pollution of the environment.

(. /etc/os-release \
     && test "$ID" = devuan \
     && test "$VERSION_CODENAME" = "$DEVUAN_CODENAME")

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
if test -f "$KEYRING_FILE"; then
    KEYRING_FILE=""
else
    command -v update-ca-certificates > /dev/null \
        || REQUIREMENTS="$REQUIREMENTS ca-certificates"
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

    curl --silent --location --show-error \
         https://files.devuan.org/devuan-archive-keyring.gpg \
        > "$KEYRING_FILE"
fi

# Create a Devuan root filesystem

mkdir -p "$ROOTFS_LOCATION"

# Packages related to booting and running PID 1 are pointless for
# container images in most use cases.  Explicitly exclude the few
# that are known to get included otherwise.

debootstrap \
    --exclude=bootlogd,initscripts,sysv-rc,sysvinit-core \
    --variant=minbase \
    --extra-suites="$DEVUAN_CODENAME-security,$DEVUAN_CODENAME-updates" \
    "$DEVUAN_CODENAME" "$ROOTFS_LOCATION" http://deb.devuan.org/merged

# Clean out the root filesystem to prevent the most egregrious,
# unneeded disk hogs.  Note that the shell glob expansion needs
# to be done *inside* the chroot.

chroot $ROOTFS_LOCATION apt-get clean
chroot $ROOTFS_LOCATION sh -c 'rm /var/lib/apt/lists/*_dists_*'

# Remove any requirements that were installed by us.

if test -n "$KEYRING_FILE"; then
    rm "$KEYRING_FILE"
fi

if test -n "$REQUIREMENTS"; then
    apt-get --quiet purge $REQUIREMENTS \
            --assume-yes --auto-remove
    test -s /tmp/apt-mark.auto \
         && apt-mark auto $(cat /tmp/apt-mark.auto) > /dev/null
fi
