#!/bin/bash

# reading the hive-site.xml mounted from configmap, and substituting the environment variables
envsubst < /mnt/hive-config/hive-site.xml > /opt/hive/conf/hive-site.xml

# Start Hive
exec /entrypoint.sh