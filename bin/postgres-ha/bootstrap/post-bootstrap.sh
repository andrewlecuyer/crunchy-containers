#!/bin/bash

# Copyright 2019 - 2020 Crunchy Data Solutions, Inc.
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

source_pid=$1
root_dir="/proc/$1/root"

export PGHOST="/crunchyadm"

pgha_env_vars=$( tr '\0' '\n' < "/proc/${source_pid}/environ"  | grep ^PGHA_ )
readarray -t pgha_env_var_arr <<< "${pgha_env_vars}"
for env_var in "${!pgha_env_var_arr[@]}"
do
    export "${pgha_env_var_arr[env_var]}"
done

source "${root_dir}/opt/cpm/bin/common/common_lib.sh"
enable_debugging

echo_info "postgres-ha post-bootstrap starting"

# When using the 'pgbackrest_init' bootstrap method, make sure backrest is stopped before writing
# to the DB.  This is because when using this bootstrap method, the current instance will still
# be connected to the pgBackRest repository for another cluster (i.e. the cluster being
# bootstrapped from), and we want to ensure there is no ability to push WAL to that repo.  Please
# note that when using 'pgbackrest_init' archive_mode should also be disabled, and this simply 
# serves as an extra precaution.
if [[ "${PGHA_BOOTSTRAP_METHOD}" == "pgbackrest_init" ]]
then
    /opt/cpm/bin/wrapper/pgbackrest stop
    err_check "$?" "post bootstrap" "Could not stop pgBackRest, ${setup_file} will not be run"
fi

if [[ "${PGHA_BOOTSTRAP_METHOD}" == "initdb" ]]
then
    # Run either a custom or the defaul setup.sql file
    if [[ -f "${root_dir}/pgconf/setup.sql" ]]
    then
        echo_info "Using custom setup.sql"
        setup_file="/pgconf/setup.sql"
    else
        echo_info "Using default setup.sql"
        setup_file="/opt/cpm/bin/sql/setup.sql"
    fi
else
    if [[ -f "${root_dir}/pgconf/post-existing-init.sql" ]]
    then
        echo_info "Using custom post-existing-init.sql"
        setup_file="/pgconf/post-existing-init.sql"
    else
        echo_info "Using default post-existing-init.sql"
        setup_file="/opt/cpm/bin/sql/post-existing-init.sql"
    fi
fi

echo_info "Running ${setup_file} file"
envsubst < "${root_dir}${setup_file}" | psql -f -

echo_info "postgres-ha post-bootstrap complete"
