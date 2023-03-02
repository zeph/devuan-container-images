#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2023 Olaf Meeuwissen

# Make sure apt and apt-get output is in the expected locale so we can
# parse output reliably.  For sort purposes it is nice to have a known
# collation order as well.

LC_ALL=C.UTF-8
export LC_ALL

apt-get --quiet update

# This count has been used to decide whether container images need to
# be upgraded so far.  However, because the apt CLI is not stable, we
# should deprecate this in favour of something that *is* stable.

upgradable_count=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

out=$(mktemp)
trap 'rm $out' 0 1 2 15

# The apt-get CLI is stable and the results of parsing its output will
# be used to replace the upgradable_count.  Parse results are reported
# for informational purposes.  Only the number of upgradable packages
# will be used to decide upgradability.

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

# We expect both counts to be identical but report any discrepancies.

if test "$upgradable_count" -ne "$dist_upgrade_count"; then
    echo "apt list --upgradable reports $upgradable_count packages"
    echo "apt-get dist-upgrade reports $dist_upgrade_count packages"
fi

test 0 -lt "$upgradable_count"
