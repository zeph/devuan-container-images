#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2022 Olaf Meeuwissen

test -n "${DEBUG+true}" && set -x

DEBIAN_CODENAME=${1:-bullseye}
DEVUAN_CODENAME=${2:-chimaera}

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

# Check we are dealing with the expected Debian environment.  Do this
# in a subshell to prevent needless pollution of the environment.

(. /etc/os-release \
     && test "$ID" = debian \
     && test "$VERSION_CODENAME" = "$DEBIAN_CODENAME")

# If necessary, temporarily install requirements to securely obtain a
# copy of the Devuan package signing key for use by APT.  Take utmost
# care not to remove already automatically installed packages in this
# step.

REQUIREMENTS=""
command -v update-ca-certificates > /dev/null \
    || REQUIREMENTS="$REQUIREMENTS ca-certificates"
command -v curl > /dev/null \
    || REQUIREMENTS="$REQUIREMENTS curl"

if test -n "$REQUIREMENTS"; then
    apt-mark showauto > /tmp/apt-mark.auto
    test -s /tmp/apt-mark.auto \
         && apt-mark manual $(cat /tmp/apt-mark.auto) > /dev/null
    apt-get --quiet update
    apt-get --quiet install $REQUIREMENTS \
            --assume-yes --no-install-recommends
fi

curl --silent --location --show-error \
     --output-dir /etc/apt/trusted.gpg.d/ \
     --remote-name https://files.devuan.org/devuan-archive-keyring.gpg

if test -n "$REQUIREMENTS"; then
    apt-get --quiet purge $REQUIREMENTS \
            --assume-yes --auto-remove
    test -s /tmp/apt-mark.auto \
         && apt-mark auto $(cat /tmp/apt-mark.auto) > /dev/null
fi

# Replace the Debian APT sources with those for Devuan.

cat << EOF > /etc/apt/sources.list
deb http://deb.devuan.org/merged $DEVUAN_CODENAME          main
deb http://deb.devuan.org/merged $DEVUAN_CODENAME-updates  main
deb http://deb.devuan.org/merged $DEVUAN_CODENAME-security main
EOF
rm -f /etc/apt/sources.list.d/*

# Migrate from Debian to Devuan.

apt-get --quiet update
apt-get --quiet upgrade --assume-yes

# Confirm we are on Devuan now.

(. /etc/os-release \
     && test "$ID" = devuan \
     && test "$VERSION_CODENAME" = "$DEVUAN_CODENAME")

# Finish up the migration.

apt-get --quiet dist-upgrade --assume-yes

if test -f /.dockerenv; then
    # Clean up more thoroughly to reduce container image size.

    apt-get --quiet clean
    rm -f /var/lib/apt/lists/*_dists_*
else
    # Finish up the migration for non-container environments.  As we
    # cannot be sure that auto-removable packages should be removed,
    # let's leave that decision to the user.
    #
    # Unless APT_ASSUME_AUTOREMOVE has been set to one of -y, --yes,
    # --assume-yes or --assume-no, this makes the script interactive
    # for such environments.  Using --assume-no makes this a no-op.

    apt-get --quiet autoremove --purge "${APT_ASSUME_AUTOREMOVE:-}"
    apt-get --quiet autoclean
fi
