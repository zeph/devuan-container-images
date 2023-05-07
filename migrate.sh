#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2023 Olaf Meeuwissen

SOURCE_IMAGE=$DEBIAN_REGISTRY/debian:$DEBIAN_CODENAME-slim
TARGET_IMAGE=$TARGET_REGISTRY/migrated:$DEVUAN_CODENAME-slim-$BUILD_ID

docker pull --quiet "$SOURCE_IMAGE"

trap "rm -f .dockerignore" EXIT HUP INT TERM
cat <<EOF > .dockerignore
*
!migrated/migrate.sh
EOF

cat <<EOF | docker build --tag "$TARGET_IMAGE" --file - .
FROM $SOURCE_IMAGE

COPY migrated/migrate.sh /tmp
RUN  dockerenv=true /tmp/migrate.sh $DEBIAN_CODENAME $DEVUAN_CODENAME
EOF

docker push --quiet "$TARGET_IMAGE"
