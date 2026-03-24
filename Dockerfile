#
# Copyright (c) 2019 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM maven:3-eclipse-temurin-21 AS build
COPY $PWD /session-service
WORKDIR /session-service
RUN mvn package -DskipTests -Dpackaging.type=jar
# Fetch RDS CA bundle in build stage so the runtime image does not need curl (CVE-2026-3805 etc.).
RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && curl -fsSL -o /session-service/rds-combined-ca-bundle.pem \
    https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem \
  && rm -rf /var/lib/apt/lists/*

FROM eclipse-temurin:21-alpine-3.23 AS fnl_base_image

RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

RUN mkdir -p /tmp && chmod 777 /tmp

COPY --from=build /session-service/rds-combined-ca-bundle.pem /tmp/rds-combined-ca-bundle.pem

# copy over target/session_service-x.y.z.jar ignore *-model.jar, that jar is
# used by cbioportal/cbioportal to import the models
COPY --from=build /session-service/target/*[0-9].jar /app.war
# CMD java ${JAVA_OPTS} -jar /app.war

# Copy and set up startup script
COPY startup.sh /
RUN chmod +x /startup.sh

ENTRYPOINT ["/startup.sh"]
