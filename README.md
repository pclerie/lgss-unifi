# LGSS Unifi Snap

This snap package is a fork of (unifi-unofficial)[https://github.com/ogra1/unifi-unofficial.git] by *Oliver Grawert*, updated to *Ubuntu Core 24* and *UniFi Network Application 9.1.120.0*.

The latest version of the controller also required an upgrade to *JDK 17*. In theory, older versions of *MongoDB* could have been used, and I did consider it as the last version compatible with the *Raspberry Pi 4 was *4.4*. All higher versions require *AVX Extensions* which are only available on the *Pi 5*. Unfortunately, *mongodb-org-server 4.4* is no longer in the official repositories, so it seemed reasonable to use the latest which is *MongoDB 8.0*. As a result, the snap will build on the *Pi 4* and *Java* will start, but *MongoDB* will silently fail with *Error code 132* in the logs. I don't have a *Pi 5* so I'll make no claim.
