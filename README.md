# LGSS Unifi Snap

This snap package is a fork of [unifi-unofficial](https://github.com/ogra1/unifi-unofficial.git) by *Oliver Grawert*, updated to *Ubuntu Core 24* and *UniFi Network Application 9.1.120.0*.

The latest version of the controller also required an upgrade to *JDK 17*. In theory, older versions of *MongoDB* could have been used, and I did consider it as the last version compatible with the *Raspberry Pi 4 was *4.4*. All higher versions require *AVX Extensions* which are only available on the *Pi 5*. Unfortunately, *mongodb-org-server 4.4* is no longer in the official repositories, so it seemed reasonable to use the latest which is *MongoDB 8.0*. As a result, the snap will build on the *Pi 4* and *Java* will start, but *MongoDB* will silently fail with *Error code 132* in the logs. I don't have a *Pi 5* so I'll make no claim.

## Updates

### Tag 0.4 - Upgrade to Unifi 9.3.45.0 (30-Jul-2025)

Version 9.3.45 was uploaded to the repository. There was an earlier 9.3.43, published earlier this month which never made it to the repository, which is why it was not snapped.

This release will also add a ARM64 build specifically for the **Raspberry Pi 5**. I finally acquired a Pi 5 to test it. I got the *8GB* version, but I see no reason why it would not run on the *2GB*. 

### Tag 0.3 - Upgrade to Unifi 9.2.87.0 (17-Jun-2025)

When I uploaded an update earlier today, I was taken by surprise when Snapcraft returned with a new version of the controller, that I was not aware of. It turns out that I had not realized that I needed to `snapcraft clean` more often. Teething problems one might say.

I pulled the build, then did a quick check, and here we are.


### Tag 0.2 - Add code to move certificates into the controller's Java Keystore (17-Jun-2025)

See the [acme/](acme/) directory for details.
