#!/bin/bash

cassandra_hostname="127.0.0.1"

. /etc/clearwater/config

. /usr/share/clearwater/cassandra_schema_utils.sh

quit_if_no_cassandra

echo "Adding/updating Cassandra schemas..."

count=0
/usr/share/clearwater/bin/poll_cassandra.sh --no-grace-period > /dev/null 2>&1

while [ $? -ne 0 ]; do
  ((count++))
  if [ $count -gt 120 ]; then
    echo "Cassandra isn't responsive, unable to add/update schemas yet"
    exit 1
  fi

  sleep 1
  /usr/share/clearwater/bin/poll_cassandra.sh --no-grace-period > /dev/null 2>&1
done

CQLSH="/usr/share/clearwater/bin/run-in-signaling-namespace cqlsh"

rc=0

if [[ ! -e /var/lib/cassandra/data/homestead_provisioning ]] || \
   [[ $cassandra_hostname != "127.0.0.1" ]];
then
  # replication_str is set up by
  # /usr/share/clearwater/cassandra-schemas/replication_string.sh
  $CQLSH -e "CREATE KEYSPACE IF NOT EXISTS homer WITH REPLICATION = $replication_str;
             USE homer;
             CREATE TABLE IF NOT EXISTS simservs (user text PRIMARY KEY, value text)
             WITH COMPACT STORAGE AND read_repair_chance = 1.0;"
  rc=$?
fi
