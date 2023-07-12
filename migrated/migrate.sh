#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2022, 2023 Olaf Meeuwissen

test -n "${DEBUG+true}" && set -x

DEBIAN_CODENAME=${1:-bullseye}
DEVUAN_CODENAME=${2:-chimaera}
DEVUAN_DEB_REPO=http://deb.devuan.org/merged

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

# Check we are dealing with the expected Debian environment.  Do this
# in a subshell to prevent needless pollution of the environment.

(. /etc/os-release
 test "$ID" = debian || exit 1
 test "$VERSION_CODENAME" = "$DEBIAN_CODENAME" && exit 0
 # If still here, we're dealing with testing/unstable codenames which
 # may or may not have -security and/or -updates suites.
 grep -E "^Suites: $DEBIAN_CODENAME( $DEBIAN_CODENAME-.*)*$" \
      /etc/apt/sources.list.d/debian.sources >/dev/null)

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


# Replace the Debian APT sources with those for Devuan.
# Non-released "releases" may be missing *-security and/or *-updates.
# Only add those suites that are available in the package repository.

> /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*

for suite in "" "-security" "-updates"; do
    code=$(curl --silent --location --show-error --head \
                --output /dev/null --write-out "%{http_code}" \
                $DEVUAN_DEB_REPO/dists/$DEVUAN_CODENAME$suite/InRelease)

    case "$code" in
        200)
            echo >&2 "adding $DEVUAN_CODENAME$suite"
            echo "deb $DEVUAN_DEB_REPO $DEVUAN_CODENAME$suite main" \
                 >> /etc/apt/sources.list
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

# Remove any requirements that were temporarily installed.

if test -n "$REQUIREMENTS"; then
    apt-get --quiet purge $REQUIREMENTS \
            --assume-yes --auto-remove
    test -s /tmp/apt-mark.auto \
         && apt-mark auto $(cat /tmp/apt-mark.auto) > /dev/null
    rm -f /tmp/apt-mark.auto
fi

# Put required archive keys into place.

case "$DEVUAN_CODENAME" in
    excalibur)
        cp /tmp/trusted.gpg.d/devuan-keyring-$DEVUAN_CODENAME-archive.gpg \
           /etc/apt/trusted.gpg.d/
        ;;
    *)
        cp /tmp/trusted.gpg.d/devuan-keyring-2016-archive.gpg \
           /etc/apt/trusted.gpg.d/
        ;;
esac

# Migrate from Debian to Devuan.

apt-get --quiet update
apt-get --quiet upgrade --assume-yes
apt-get --quiet dist-upgrade --assume-yes

# Downgrade any installed packages that are not in the Devuan APT
# sources.  Such packages are marked as "local" by APT and should
# have been replaced by a Devuanized version.  However, when that
# version is older than the Debian version, it is not included in
# the upgrades :-/

apt-mark showauto > /tmp/apt-mark.auto
apt-get --quiet install --assume-yes --allow-downgrades \
        $(apt list --installed 2>/dev/null \
              | sed -n "/,local]/s/[^/]*$/$DEVUAN_CODENAME/p")
apt-mark auto $(cat /tmp/apt-mark.auto) >/dev/null
rm -f /tmp/apt-mark.auto

# If there are *still* "local" packages at this point, something
# probably went wrong.

local_packages=$(apt list --installed 2>/dev/null \
                     | sed -n '/,local]/s/[^/]*$//p')
if test -n "$local_packages"; then
    echo >&2 "local packages remaining: $local_packages"
    exit 1
fi

# Confirm we are on the expected Devuan release now.

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

# Clean up

if test -f /.dockerenv || test "$dockerenv" = "true"; then
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
