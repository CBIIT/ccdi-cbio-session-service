#
# Copyright (c) 2019 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM maven:3-eclipse-temurin-21 as build
COPY $PWD /session-service
WORKDIR /session-service
RUN mvn package -DskipTests -Dpackaging.type=jar

# Add AWS DocumentDB certificate
RUN curl -o /tmp/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem

# Use the latest patched version to address CVE-2025-50059 and other Java vulnerabilities

#FROM eclipse-temurin:21-alpine AS fnl_base_image
FROM eclipse-temurin:21-ubi10-minimal AS fnl_base_image

RUN mkdir -p /tmp && chmod 777 /tmp

# Add AWS DocumentDB certificate
#RUN apk add curl && curl -o /tmp/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem

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
COPY --from=build /tmp/rds-combined-ca-bundle.pem /tmp/rds-combined-ca-bundle.pem
# CMD java ${JAVA_OPTS} -jar /app.war


# Copy and set up startup script
COPY startup.sh /
RUN chmod +x /startup.sh

ENTRYPOINT ["/startup.sh"]
