#!/bin/bash

# Copyright 2020 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

root_dir="/proc/$1/root"

echo_info "Starting background process to monitor Patroni initization and restart the database if needed"
# Wait until the health endpoint for the local primary or replica to return 200 indicating it is running
status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/health" 2> /dev/null)
until [[ "${status_code}" == "200" ]]
do
    sleep 1
    echo "Cluster not yet inititialized, retrying" >> "/tmp/patroni_initialize_check.log"
    status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/health" 2> /dev/null)
done

# Enable pgbackrest
if [[ "${PGHA_PGBACKREST}" == "true" ]]
then
    source "/opt/cpm/bin/pgbackrest/pgbackrest-post-bootstrap.sh"
fi

if [[ "${PGHA_INIT}" == "true" ]]
then
    echo_info "PGHA_INIT is '${PGHA_INIT}', waiting to initialize as primary"
    # Wait until the master endpoint returns 200 indicating the local node is running as the current primary
    status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/master" 2> /dev/null)
    until [[ "${status_code}" == "200" ]]
    do
        sleep 1
        echo "Not yet running as primary, retrying" >> "/tmp/patroni_initialize_check.log"
        status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/master" 2> /dev/null)
    done
fi

# The following logic only applies to bootstrapping and initializing clusters that are
# not standby clusters.  Specifically, this logic expects the database to exit recovery
# and become writable.
if [[ "${PGHA_INIT}" == "true" && "${PGHA_STANDBY}" != "true" ]]
then
    # Ensure the cluster is no longer in recovery
    until [[ $(psql -At -c "SELECT pg_catalog.pg_is_in_recovery()") == "f" ]]
    do
        echo_info "Detected recovery during cluster init, waiting one second..."
        sleep 1
    done

    # if the bootstrap method is not "initdb", we assume we're running an init job and now
    # proceed with shutting down Patroni and the database
    if [[ "${PGHA_BOOTSTRAP_METHOD}" != "pgbackrest_init" ]]
    then
        # Apply enhancement modules
        echo_info "Applying enahncement modules"
        for module in /opt/cpm/bin/modules/*.sh
        do
            echo_info "Applying module ${module}"
            source "${module}"
        done

        # If there are any tablespaces, create them as a convenience to the user, both
        # the directories and the PostgreSQL objects
        source /opt/cpm/bin/common/pgha-tablespaces.sh
        tablespaces_create_postgresql_objects "${PGHA_USER}"

        # Run audit.sql file if exists
        if [[ -f "/pgconf/audit.sql" ]]
        then
            echo_info "Running custom audit.sql file"
            psql < "/pgconf/audit.sql"
        fi
    else
        echo_info "Init job completed, shutting down the cluster and removing from the DCS"

        # pause Patroni, stop the database, and then remove the cluster from the DCS
        patronictl pause
        patronictl reload "${PATRONI_SCOPE}" --force &> /dev/null
        pg_ctl stop -m fast -D "${PATRONI_POSTGRESQL_DATA_DIR}"
        printf '%s\nYes I am aware\n%s\n' "${PATRONI_SCOPE}" "${PATRONI_NAME}" | patronictl remove "${PATRONI_SCOPE}" &> /dev/null
        err_check "$?" "Remove from DCS" "Unable to remove cluster from the DCS following init job"
        echo_info "Successfully removed cluster from the DCS"

        # now kill patroni and sshd
        killall patroni
        killall sshd

        while killall -0 patroni; do
            echo_info "Waiting for Patroni to terminate following init job..."
            sleep 1
        done
    fi
fi

touch "/crunchyadm/pgha_initialized"  # write file to indicate the cluster is fully initialized
echo_info "Node ${PATRONI_NAME} fully initialized for cluster ${PATRONI_SCOPE} and is ready for use"
