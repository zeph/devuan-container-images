#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2023 Olaf Meeuwissen

: "${BUILD_VARIANT:=}"

SOURCE_IMAGE=$SOURCE_REGISTRY/$1:$DEVUAN_CODENAME$BUILD_VARIANT-$BUILD_ID
TARGET_IMAGE=$TARGET_REGISTRY/$1

docker pull --quiet "$SOURCE_IMAGE"
TIMESTAMP=$(docker inspect --format='{{.Created}}' "$SOURCE_IMAGE" | sed 's/T.*//')

docker tag "$SOURCE_IMAGE" \
       "$TARGET_IMAGE:$DEVUAN_CODENAME$BUILD_VARIANT-$TIMESTAMP"
docker push --quiet \
       "$TARGET_IMAGE:$DEVUAN_CODENAME$BUILD_VARIANT-$TIMESTAMP"

docker tag "$SOURCE_IMAGE" \
       "$TARGET_IMAGE:$DEVUAN_CODENAME$BUILD_VARIANT"
docker push --quiet \
       "$TARGET_IMAGE:$DEVUAN_CODENAME$BUILD_VARIANT"

docker tag "$SOURCE_IMAGE" \
       "$TARGET_IMAGE:$DEVUAN_SUITE$BUILD_VARIANT"
docker push --quiet \
       "$TARGET_IMAGE:$DEVUAN_SUITE$BUILD_VARIANT"

test "$DEVUAN_SUITE" = stable || exit 0

: "${BUILD_VARIANT:=-latest}"
BUILD_VARIANT=${BUILD_VARIANT#-}

docker tag "$SOURCE_IMAGE" \
       "$TARGET_IMAGE:$BUILD_VARIANT"
docker push --quiet \
       "$TARGET_IMAGE:$BUILD_VARIANT"
