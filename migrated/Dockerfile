# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: © 2022, 2023 Olaf Meeuwissen

ARG DEBIAN_CODENAME=bullseye
ARG IMAGE_VARIANT=-slim

FROM debian:$DEBIAN_CODENAME$IMAGE_VARIANT

# ARG declarations before the first FROM are no longer in scope in the
# build stage(s).  For every build stage, i.e. after every FROM, build
# time ARGs need to be redeclared (and with the same default value, if
# any) for any ARGs that are used in the build stage.
#
# See https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact

ARG DEBIAN_CODENAME=bullseye
ARG DEVUAN_CODENAME=chimaera

COPY migrate.sh /tmp
RUN  dockerenv=true /tmp/migrate.sh $DEBIAN_CODENAME $DEVUAN_CODENAME
