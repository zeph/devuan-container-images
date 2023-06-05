---
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: © 2022, 2023 Olaf Meeuwissen
---

Devuan GNU+Linux is a fork of Debian without `systemd` that allows
users to reclaim control over their system by avoiding unnecessary
entanglements and ensuring [Init Freedom][IF].

The `devuan/migrated` container images are built starting from their
corresponding `debian:<release>-slim` image, replacing the Debian APT
sources with sources appropriate for Devuan and doing an upgrade.  To
see the details of what has been done, see the `/tmp/migrate.sh` file
included in the image.

These images are used to build the [`devuan/devuan`][DD] images.

# Available Tags

Tags for all [Devuan releases][DR] since `ascii` are available.  The
`<release>-slim` tags point to the most recently published image for
a release.  Corresponding suite names can be used as tags instead of
release names as well, e.g. `testing-slim`.

Release and suite name tags move to a *different* image every time
updated images are made available.  To help you stay on a specific
version of an image, timestamped tags for each release are provided
in `<release>-slim-YYYY-MM-DD` format.

Finally, the `slim` tag is an alias for `stable-slim`.

Summarizing this by means of an example, for `ceres` the following
tags are available:

- `ceres-slim-YYYY-MM-DD` formatted tags for all published images
  built for the `ceres` release
- a `ceres-slim` release tag pointing to the `ceres-slim-YYYY-MM-DD`
  image that was published most recently
- an `unstable-slim` suite tag that aliases `ceres-slim`

## Archived Releases

Images for maintained releases are updated on a needs basis.  Once a
release is archived, the image is no longer updated.  As a result,
images for an archived release will point to an APT source that no
longer exists.

While you should upgrade to a maintained release as soon as possible,
if you absolutely *must* continue using an archived release, you can
"fix" the image's APT sources by running

``` sh
sed -i 's,//deb,//archive,; /-updates/d' /etc/apt/sources.list
```

# Getting Help

For questions specific to these images, please ask around on the [DNG
mailing list][ML].

# Development

These images are maintained at the [container-images][CI] project.
All code to build images and any issues pertaining to them can be
found there.  New issues can be submitted there as well.

 [CI]: https://git.devuan.org/paddy-hack/container-images
 [DD]: https://hub.docker.com/r/devuan/devuan
 [DR]: https://www.devuan.org/os/releases
 [IF]: https://www.devuan.org/os/init-freedom
 [ML]: https://mailinglists.dyne.org/cgi-bin/mailman/listinfo/dng
