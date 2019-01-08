#!/usr/bin/env bash

# This script will run as the postgres user due to the Dockerfile USER directive
set -e

# Setup postgres CONF file
source /setup-conf.sh

# Setup ssl
source /setup-ssl.sh

# Setup pg_hba.conf
source /setup-pg_hba.sh

if [ -f /setup-citus.sh ]; then
    echo "Setup citus"
    source /setup-citus.sh
fi

if [ -z "$REPLICATE_FROM" ]; then
	# This means this is a master instance. We check that database exists
	echo "Setup master database"
	source /setup-database.sh
else
	# This means this is a slave/replication instance.
	echo "Setup slave database"
	source /setup-replication.sh
fi
