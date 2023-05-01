#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2023 Olaf Meeuwissen

SOURCE_IMAGE=$SOURCE_REGISTRY/migrated:$DEVUAN_CODENAME
docker pull --quiet "$SOURCE_IMAGE" >&2
if docker run -v "$PWD":/mnt:ro "$SOURCE_IMAGE" /mnt/upgradable.sh >&2; then
    echo migration
    exit
fi

SOURCE_IMAGE=$SOURCE_REGISTRY/devuan:$DEVUAN_CODENAME
docker pull --quiet "$SOURCE_IMAGE" >&2
if docker run -v "$PWD":/mnt:ro "$SOURCE_IMAGE" /mnt/upgradable.sh >&2; then
    echo bootstrap
    exit
fi

exit 0
