#!/bin/bash

readonly HUMAN_ROLE=$1
shift

"$@"


readonly dbname=postgres
if [[ "${*: -3:1}" == "on_role_change" && "${*: -2:1}" == "master" ]]; then
    # Large clusters may need more than 30s to finish recovery after promotion,
    # which caused post_init.sh (and thus extension upgrades like timescaledb) to be skipped silently.
    num=120
    while  [[ $((num--)) -gt 0 ]]; do
        if [[ "$(psql -d $dbname -tAc 'SELECT pg_catalog.pg_is_in_recovery()')" == "f" ]]; then
            vacuumdb -aZ > /dev/null 2>&1 &
            exec /scripts/post_init.sh "$HUMAN_ROLE" "$dbname"
        else
            sleep 1
        fi
    done
fi
