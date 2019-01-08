#!/usr/bin/env bash

source /env-data.sh

echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/10/postgresql.conf.sample
echo "shared_preload_libraries='citus'" >> /usr/lib/tmpfiles.d/postgresql.conf
echo "shared_preload_libraries='citus'" >> $ROOT_CONF/postgresql.conf
