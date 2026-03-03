#
# Copyright (c) 2019 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM maven:3-eclipse-temurin-21 as build
COPY $PWD /session-service
WORKDIR /session-service
RUN mvn package -DskipTests -Dpackaging.type=jar

# Use the latest patched version to address CVE-2025-50059 and other Java vulnerabilities
# Fix CVE-2026-21945: Use Eclipse Temurin 21.0.10+ (DoS in Security/certificate checking)

FROM eclipse-temurin:21.0.10_7-jre-alpine AS fnl_base_image

# Fix CVE-2025-15467: Upgrade OpenSSL to patched version (3.0.19 / 3.3.6 / 3.4.4 / 3.5.5 / 3.6.1+)
# Stack buffer overflow in CMS AEAD parsing; Alpine delivers fix via apk upgrade
# Fix CVE-2026-25210: libexpat integer overflow in doContent/tag buffer reallocation (expat < 2.7.4).
# Fixed in expat 2.7.4+; Alpine 3.20+ ships 2.7.4-r0. apk upgrade below gets patched expat when base is Alpine 3.20+.
# Fix CVE-2026-22801: LIBPNG heap buffer over-read in png_write_image_* (libpng 1.6.26–1.6.53).
# Fixed in libpng 1.6.54+; Alpine 3.20+ ships 1.6.55-r0. apk upgrade below gets patched libpng when base is Alpine 3.20+.
# Fix CVE-2025-13151: libtasn1 stack buffer overflow in asn1_expend_octet_string (libtasn1 <= 4.20.0).
# Fixed in libtasn1 4.21.0+; Alpine 3.20+ ships 4.21.0-r0. apk upgrade below gets patched libtasn1 when base is Alpine 3.20+.
# Fix CVE-2025-32988: GnuTLS double-free in SAN otherName export (gnutls < 3.8.10).
# Fix CVE-2024-12243: GnuTLS/libtasn1 DoS via inefficient DER cert decoding (gnutls 3.8.11+ / 3.8.12+ on Alpine).
# Fixed in GnuTLS 3.8.10+; Alpine 3.20+ ships 3.8.12-r0. apk upgrade below gets patched gnutls when base is Alpine 3.20+.
# Fix CVE-2025-68973: GnuPG out-of-bounds write in armor_filter (gnupg < 2.4.9, or < 2.2.51 ExtendedLTS).
# Fixed in GnuPG 2.4.9+; Alpine 3.20+ ships gnupg 2.4.9-r0. apk upgrade below gets patched gnupg when base is Alpine 3.20+.
# Fix CVE-2025-46394: BusyBox tar filenames hidden via terminal escape sequences (busybox through 1.37.0).
# Fixed in busybox 1.36.1-r31 (3.20), 1.36.1-r21 (3.19), 1.37.0-r14+ (3.21+). apk upgrade below gets patched busybox when base is Alpine 3.19+.
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

RUN mkdir -p /tmp && chmod 777 /tmp

# Add AWS DocumentDB certificate
RUN apk add curl && curl -o /tmp/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem

# Fix CVE-2025-6965: Upgrade SQLite to version 3.50.2 or above
# Fix CVE-2025-40909: Upgrade Perl to address threads working directory race condition
# Add AWS DocumentDB certificate
# RUN apt-get update && \
#     apt-get upgrade -y libsqlite3-0 perl perl-base && \
#     apt-get install -y curl && \
#     curl -o /tmp/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*


# copy over target/session_service-x.y.z.jar ignore *-model.jar, that jar is
# used by cbioportal/cbioportal to import the models
COPY --from=build /session-service/target/*[0-9].jar /app.war
# CMD java ${JAVA_OPTS} -jar /app.war


# Copy and set up startup script
COPY startup.sh /
RUN chmod +x /startup.sh

ENTRYPOINT ["/startup.sh"]