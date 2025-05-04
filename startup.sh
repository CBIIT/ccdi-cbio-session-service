#!/bin/bash
# filepath: startup.sh

# Import the RDS cert into a truststore
keytool -importcert -trustcacerts -alias rds-root -file /tmp/rds-combined-ca-bundle.pem  -keystore /tmp/rds-truststore.jks -storepass abcdef -noprompt

# Start the application with MongoDB SSL settings
exec java ${JAVA_OPTS} \
    -Djavax.net.ssl.trustStore=/tmp/rds-truststore.jks \
    -Djavax.net.ssl.trustStorePassword=abcdef \
    -Dspring.data.mongodb.uri=${MONGODB_URI} \
    -jar /app.war