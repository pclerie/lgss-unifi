# Deploying ACME certificates

Release v0.2 of ***lgss-unifi*** adds a script (`/snap/bin/deploy-certificate`) to facilitate automation of certificate renewals in the *Java* context. As with web browsers, *Java* keeps its own store of *Root Certificates*, which is called a *keystore*, sometimes a *truststore*, managed by the `keytool` utility. The *Unifi Controller* uses such a *keystore* to store the certificate its web server presents to the browser. I suspect most people will just create an exception in their browser to trust that certificate. But some people will want to change to a properly signed signed certificate, be it from a public or a private *Certificate Authority*. But a CA will only deliver the *raw* certificate. It's to the user to get that file in the *keystore*. `deploy-certificate` does just that.

However, to allow users to work with their preferred ACME client, to keep things simple and because the snap is strictly confined, some glue needs to be manually added.

## Certificates in *Unifi Network App*

As mentioned earlier, the *Unifi Controller* expects its certificate to be held in a *Java keystore*,which in our case is a file aptly name `keystore`, located at `$SNAP_DATA/data/keystore`. Importantly, this `SNAP_DATA` location is **writable** from outside the snap. Our goal is to include our newly obtained certificate into this keystore.

Obviously, the first thing to do is to obtain a new certificate. It is up to the user to decide which of the many *ACME clients* to use and how to configure it. At a minimum, you will need the certificate chain (certificate + signing intermediate) and the key. We´ll call the first `CERT_FULLCHAIN` and the second `CERT_PRIVKEY`. Crucially, the tool getting the certificate will most likely deliver it to location **outside** the snap, and consequently will be inaccessible by any program contained in the snap. Such is the purpose of confinement.

Next, recall that we must use `$JAVA_BIN/keytool` to manage the keystore. From inside the snap, it cannot read from or write to anywhere outside the snap, so it has no access to the certificate and the key. Therefore, we need to somehow place `CERT_FULLCHAIN` and `CERT_PRIVKEY` in a location equally accessible to `$JAVA_BIN/keytool`. Now we know that `SNAP_DATA` meets both requirements, and, the keystore is already there. So, we need to copy certificate and key to `SNAP_DATA`, at which time `$JAVA_BIN/keytool` can import `CERT_FULLCHAIN` and `CERT_PRIVKEY` into the keystore.

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

As you can see, this is actually very simple as all the hard work is being done in that one-liner in Step 3. The rest is just the glue code previously mentioned.

I believe most ACME clients provide hooks to automate deployment of certificates. This code can be put in a single file and attached to the appropriate hook.

*Certbot* has three hooks for renewal operations. 

- `pre` copies certificate and key (Step 1), then stops the controller (Step 2)
- `deploy` executes `deploy-certificate` (Step 3)
- `post` restarts the controller and cleans up.

It's probably much simpler to put it all in `deploy`.









