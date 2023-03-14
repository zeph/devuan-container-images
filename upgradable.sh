#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2023 Olaf Meeuwissen

# Make sure apt-get output is in the expected locale so we can parse
# output reliably.  For sorting purposes, it is nice to have a known
# collation order as well.

LC_ALL=C.UTF-8
export LC_ALL

apt-get --quiet update

out=$(mktemp)
trap 'rm $out' 0 1 2 15

# Simulate an upgrade that intelligently handles changing dependencies
# with new versions of packages and get rid of any packages that are
# no longer needed.  Collect command output for parsing and feedback
# purposes.

apt-get dist-upgrade --auto-remove --simulate > "$out"

dist_upgrade_count=0
upgradable=$(awk '$1 == "Inst" && $3 ~ /^\[/ { print $2 }' "$out")
if test -n "$upgradable"; then
    echo "The following packages can be upgraded:"
    echo "$upgradable" | sed 's/^/- /' | sort
    dist_upgrade_count=$(echo "$upgradable" | wc -l)
fi

additions=$(awk '$1 == "Inst" && $3 ~ /^\(/ { print $2 }' "$out")
if test -n "$additions"; then
    echo "This will add the following packages:"
    echo "$additions" | sed 's/^/- /' | sort
fi

removable=$(awk '$1 == "Remv" { print $2 }' "$out")
if test -n "$removable"; then
    echo "The following packages can be removed:"
    echo "$removable" | sed 's/^/- /' | sort
fi

test 0 -lt "$dist_upgrade_count"
