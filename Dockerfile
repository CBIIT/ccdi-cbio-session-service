#
# Copyright (c) 2019 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM maven:3-eclipse-temurin-11 as build
COPY $PWD /session-service
WORKDIR /session-service
RUN mvn package -DskipTests -Dpackaging.type=jar

FROM eclipse-temurin:11

RUN mkdir -p /tmp && chmod 777 /tmp

# Add AWS DocumentDB certificate
RUN curl -o /tmp/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem

# Copy the built JAR file from the build stage
COPY --from=build /session-service/target/*[0-9].jar /app.war

# Set default Java options for TLS
# ENV JAVA_OPTS="-Djavax.net.ssl.trustStore=/tmp/rds-truststore.jks -Djavax.net.ssl.trustStorePassword=changeit"


# Copy and set up startup script
COPY startup.sh /
RUN chmod +x /startup.sh

ENTRYPOINT ["/startup.sh"]