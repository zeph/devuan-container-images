---
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: © 2022, 2023 Olaf Meeuwissen
---

Devuan GNU+Linux is a fork of Debian without `systemd` that allows
users to reclaim control over their system by avoiding unnecessary
entanglements and ensuring [Init Freedom][IF].

The `devuan/devuan` container images are built within the confines
of their corresponding [`devuan/migrated`][DM] images.

# Available Tags

Tags for all [Devuan releases][DR] since `ascii` are available.  The
`<release>` tags point to the most recently published image for
a release.  Corresponding suite names can be used as tags instead of
release names as well, e.g. `testing`.

Release and suite name tags move to a *different* image every time
updated images are made available.  To help you stay on a specific
version of an image, timestamped tags for each release are provided
in `<release>-YYYY-MM-DD` format.

Finally, the `latest` tag is an alias for `stable`.

Summarizing this by means of an example, for `ceres` the following
tags are available:

- `ceres-YYYY-MM-DD` formatted tags for all published images built
  for the `ceres` release
- a `ceres` release tag that points to the `ceres-YYYY-MM-DD` image
  that was published most recently
- an `unstable` suite tag that aliases the `ceres` release tag

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
 [DM]: htttps://hub.docker.com/r/devuan/migrated
 [DR]: https://www.devuan.org/os/releases
 [IF]: https://www.devuan.org/os/init-freedom
 [ML]: https://mailinglists.dyne.org/cgi-bin/mailman/listinfo/dng
