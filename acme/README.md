# Deploying ACME certificates

Release v0.2 of ***lgss-unifi*** adds a script (`/snap/bin/deploy-certificate`) to facilitate integration with Certificate Authorities whether external (ex: [Let's Encrypt](https://letsencrypt.org)) or internal (ex: [FreeIPA](https://freeipa.org), [SmallStep](https://smallstep.com)). After obtaining a certificate from any source, it is necessary to integrate it with the *Java* SSL infrastructure. The code required is now built into this snap. However, to allow users to work with their preferred ACME client, to keep things simple and because of the strict confinement, some glue needs to be manually added.

## Certificates in *Unifi Network App*

The controller expects its certificate to be held in a *Java keystore* which is managed by `keytool` (located at `$JAVA_BIN/keytool`), a utility that will generate, import, export and otherwise manage certificates. In our case, this store is a file located at `$SNAP_DATA/data/keystore`. Importantly, this `SNAP_DATA` location is *writable* from outside the snap. Our goal is to include our newly obtained certificate into this keystore.

Obviously, the first thing to do is to obtain a new certificate. It is up to the user to decide which of the many *ACME clients* to use and how to configure it. At a minimum, you will need the certificate chain (certificate + signing intermediate) and the key. We´ll call the first `CERT_FULLCHAIN` and the second `CERT_PRIVKEY`.

Next, recall that `$JAVA_BIN/keytool`, from inside the snap cannot read from or write to anywhere outside the snap, so it has no access to the certificate and the key. Therefore, we need to place `CERT_FULLCHAIN` and `CERT_PRIVKEY` in a location accessible to `$JAVA_BIN/keytool` as well from the outside. As mentioned previously, `SNAP_DATA` meets both requirements and the keystore is already there. So, we now copy certificate and key to `SNAP_DATA`.

At this point, we can now call `$JAVA_BIN/keytool` and incorporate `CERT_FULLCHAIN` and `CERT_PRIVKEY` in *keystore*.

That convoluted description above is basically the glue required. We now need to write code for the following steps:

- Copy `CERT_FULLCHAIN` and `CERT_PRIVKEY` to `SNAP_DATA`
- Stop the controller service
- Use `deploy-certificate` to import the certificate into the keystore
- Restart the controller service
- Remove unneeded certificate and key

## Deploying certificate to *LGSS Unifi*

I am most familiar with the ***Certbot*** ACME client, so the example code below will use the standard *certbot* layout.

#### Step 1: Copy certificate and key to the snap

```
#!/bin/bash

# Let's Encrypt renewal hook to deploy certificate to the Unifi Nework App Java Keystore.

CERT_PATH=/etc/letsencrypt/live/$(hostname --fqdn)
UNIFI_DATA=/var/snap/lgss-unifi/current/data

# Copy certificate and key to Unifi data directory
cp ${CERT_PATH}/fullchain.pem ${UNIFI_DATA}/fullchain.pem
cp ${CERT_PATH}/privkey.pem ${UNIFI_DATA}/privkey.pem
```

#### Step 2: Stop the controller

```
#!/bin/bash

systemctl stop snap.lgss-unifi.unifi.service

```

#### Step 3: Import certificate into keystore

```
#!/bin/bash

/snap/bin/lgss-unifi.deploy-certificate > /dev/null 2>&1

```

#### Step 4: Start the controller

```
#!/bin/bash

systemctl start snap.lgss-unifi.unifi.service

```

#### Step 5: Remove no longer needed files

```
#!/bin/bash

UNIFI_DATA=/var/snap/lgss-unifi/current/data

# Clean up
rm ${UNIFI_DATA}/privkey.pem
rm ${UNIFI_DATA}/fullchain.pem

```

As you can see, this is actually very simple as all the hard work is being done in that one-liner in Step 3. The rest is just the glue code mentioned in that first paragraph.

I believe most ACME clients provide hooks to automate deployment of certificates. This code can be put in a single file and attached to the appropriate hook.

*Certbot* has three hooks for renewal operations. 

- `pre` copies certificate and key (Step 1), then stops the controller (Step 2)
- `deploy` executes `deploy-certificate` (Step 3)
- `post` restarts the controller and cleans up.

I much prefer putting it all in `deploy`. Much simpler.









