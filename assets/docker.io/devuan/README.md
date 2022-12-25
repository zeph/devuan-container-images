---
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: © 2022 Olaf Meeuwissen
---

Devuan GNU+Linux is a fork of Debian without `systemd` that allows
users to reclaim control over their system by avoiding unnecessary
entanglements and ensuring [Init Freedom][IF].

# Available Tags

Tags for all maintained [Devuan releases][DR] are available.  These
`<release>` tags point to the most recently published image for a
release.  The corresponing suite names can be used as tags as well,
e.g. `testing`.

Release and suite name tags move to a *different* image every time
updated images are made available.  To help you stay on a specific
version of an image, timestamped tags for each release are provided
(in `<release>-YYYY-MM-DD` format) as well.

Finally, the `latest` tag is an alias for `stable`.

Summarizing this by means of an example, for `ceres` the following
tags are available:

- `ceres-YYYY-MM-DD` formatted tags for all published images built
  for the `ceres` release
- a `ceres` tag that points to the most recent `ceres-YYYY-MM-DD`
  image
- an `unstable` tag that aliases `ceres`

# Getting Help

For questions specific to these images, please ask around on the
[DNG mailing list][ML].

# Development

These images are maintained at the [container-images][CI] project.
All code to build images and any issues pertaining to them can be
found there.  New issues can be submitted there as well.

 [CI]: https://git.devuan.org/paddy-hack/container-images
 [DR]: https://www.devuan.org/os/releases
 [IF]: https://www.devuan.org/os/init-freedom
 [ML]: https://mailinglists.dyne.org/cgi-bin/mailman/listinfo/dng
