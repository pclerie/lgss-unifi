#!/usr/bin/env bash

# unifi_ssl_import.sh
# UniFi Controller SSL Certificate Import Script for Unix/Linux Systems
# by Steve Jenkins <http://www.stevejenkins.com/>
# Part of https://github.com/stevejenkins/ubnt-linux-utils/
# Incorporates ideas from https://source.sosdg.org/brielle/lets-encrypt-scripts
# Version 2.8
# Last Updated Jan 13, 2017

# REQUIREMENTS
# 1) Assumes you have a UniFi Controller installed and running on your system.
# 2) Assumes you already have a valid 2048-bit private key, signed certificate,
#    and certificate authority chain file. The Controller UI will not work with a
#    4096-bit certificate. See http://wp.me/p1iGgP-2wU for detailed instructions
#    on how to generate those files and use them with this script.

# KEYSTORE BACKUP
# Even though this script attempts to be clever and careful in how it backs up
# your existing keystore, it's never a bad idea to manually back up your
# keystore (located at $UNIFI_DIR/data/keystore on RedHat systems or
# /$UNIFI_DIR/keystore on Debian/Ubunty systems) to a separate directory before
# running this script. If anything goes wrong, you can restore from your
# backup, restart the UniFi Controller service, and be back online immediately.

#--------------------------------------------------------------------
# * Modified by: Philippe Clérié <pclerie@logisys.ht>
#   Date: 15-Aug-2022
#
#     - Removed everything not strictly for Let's Encrypt and Certbot
#     - Removed non-debian specificities
#     - Removed extra new lines in printf messages
#
# * Heavily modified for inclusion in a snap of the Unifi Network App
#   Date: 09-Jun-2025
#
#   At this point, the script barely resembles what I started with.
#   So, any problem is mine and mine only.
#
#--------------------------------------------------------------------

# Environment variables for moving (or copying) a certificate to 
# the application's *Java* Keystore.
 
# Unifi data directory
UNIFI_DATA=${SNAP_DATA}/data

# *Java* file path
JAVA_BIN=${SNAP}/usr/lib/jvm/java-17-openjdk-${SNAP_ARCH}/bin

# Keystore parameters
KEYSTORE_FILE=${UNIFI_DATA}/keystore

# Name and password for the certificate
KEYSTORE_ALIAS=unifi
KEYSTORE_PASSWORD=aircontrolenterprise

# Because of containment issues within the snap, it is best to require
# that the certificate and the key be moved or copied into the snap.
CERT_PRIVKEY=${UNIFI_DATA}/privkey.pem
CERT_FULLCHAIN=${UNIFI_DATA}/fullchain.pem
if [ ! -e ${CERT_PRIVKEY} ] || [ ! -e ${CERT_FULLCHAIN} ]
then
    logger -t unifi -p daemon.err 'Update aborted: missing key or certificate file.' 
    exit 1
fi

# Check to see whether certificate has changed.
if [ -f ${CERT_PRIVKEY}.md5 ] && md5sum -c ${CERT_PRIVKEY}.md5 &>/dev/null
then
	# MD5 remains unchanged, exit the script
	logger -t unifi -p daemon.info "Certificate is unchanged, no update is necessary."
	exit 0
fi

# Write a new MD5 checksum based on the updated certificate	
md5sum ${CERT_PRIVKEY} > ${CERT_PRIVKEY}.md5

# Create keystore backup. Overwrite existing backup file.
cp "${KEYSTORE_FILE}" "${KEYSTORE_FILE}.orig"
	 
# Create temp files
P12_TEMP=$(mktemp)

# Export your existing SSL key, cert, and CA data to a PKCS12 file
openssl pkcs12 -export \
    -in "${CERT_FULLCHAIN}" \
    -inkey "${CERT_PRIVKEY}" \
    -out "${P12_TEMP}" -passout pass:"${KEYSTORE_PASSWORD}" \
    -name "${KEYSTORE_ALIAS}"
#
# Delete the previous certificate data from keystore to avoid "already exists" message
${JAVA_BIN}/keytool -delete -alias "${KEYSTORE_ALIAS}" -keystore "${KEYSTORE_FILE}" -deststorepass "${KEYSTORE_PASSWORD}"
	
# Import the temp PKCS12 file into the UniFi keystore
if ${JAVA_BIN}/keytool -importkeystore \
    -srckeystore "${P12_TEMP}" -srcstoretype PKCS12 \
    -srcstorepass "${KEYSTORE_PASSWORD}" \
    -destkeystore "${KEYSTORE_FILE}" \
    -deststorepass "${KEYSTORE_PASSWORD}" \
    -destkeypass "${KEYSTORE_PASSWORD}" \
    -alias "${KEYSTORE_ALIAS}" -trustcacerts
then
    # Clean up temp files
    rm -f "${P12_TEMP}"
    logger -t unifi -p daemon.info "New certificate is now deployed!"
    exit 0
else
    logger -t unifi -p daemon.info "Keystore update aborted: failed writing new certificate."
    exit 1
fi

# The UniFi Controller should be restarted to pick up the updated keystore.
# This cannot be done from within the snap.
