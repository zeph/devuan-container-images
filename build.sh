#!/bin/sh -eu
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2023 Olaf Meeuwissen

SOURCE_IMAGE=$SOURCE_REGISTRY/migrated:$DEVUAN_CODENAME-slim
TARGET_IMAGE=$TARGET_REGISTRY/devuan:$DEVUAN_CODENAME-$BUILD_ID

if test "$SOURCE_REGISTRY" = "$PUBLIC_REGISTRY"; then
    docker pull --quiet "$SOURCE_IMAGE"
else
    # We are building on a non-default branch.  A migrated image for
    # the branch may or may not exist.  Try pulling it and fall back
    # to the public registry if that fails.
    if ! docker pull --quiet "$SOURCE_IMAGE"; then
        SOURCE_IMAGE=$PUBLIC_REGISTRY/migrated:$DEVUAN_CODENAME-slim
        docker pull --quiet "$SOURCE_IMAGE"
    fi
fi

# The beowulf and later releases all warn about a failure to mount
# /proc in the root filesystem but ascii treats that as an error.
# Adding `--privileged` makes it pass.  More limited escalations
# of privileges such as `--security-opt seccomp=unconfined` and
# `--cap-all SYS_ADMIN` do not.
test "$DEVUAN_CODENAME" = "ascii" && DOCKER_OPTS=--privileged

docker run --rm ${DOCKER_OPTS:-} \
       --volume "$PWD":/mnt \
       --workdir /mnt \
       "$SOURCE_IMAGE" ./bootstrap.sh "$DEVUAN_CODENAME" _targets

cp -a overlays/base/* _targets/"$DEVUAN_CODENAME"
cp -a overlays/"$DEVUAN_CODENAME"/* _targets/"$DEVUAN_CODENAME"

tar -caf _targets/"$DEVUAN_CODENAME".tar \
    --exclude-from excludes/base \
    --exclude-from excludes/"$DEVUAN_CODENAME" \
    --directory _targets/"$DEVUAN_CODENAME" .

trap "rm -r .dockerignore" EXIT HUP INT TERM
cat <<EOF > .dockerignore
*
!_targets/$DEVUAN_CODENAME.tar
EOF

cat <<EOF | docker build --tag "$TARGET_IMAGE" --file - .
FROM scratch
ADD _targets/$DEVUAN_CODENAME.tar /
EOF

docker push --quiet "$TARGET_IMAGE"
