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

source /opt/cpm/bin/common/common_lib.sh
enable_debugging

source /opt/cpm/bin/common/pgha-common.sh

# set PGHA_REPLICA_REINIT_ON_START_FAIL, which determines if replica should be reinitialized
# if a start failure is detected
export $(get_replica_reinit_start_fail)

# Set the PATRONI_NAME environment variable
export $(get_patroni_name)

# Exit right away if support for "start failed" reinit is not enabled
if [[ "${PGHA_REPLICA_REINIT_ON_START_FAIL}" != "true" ]]
then
    exit 0
fi

# determine if a backup is in progress following a failover (i.e. the promotion of a replica)
# by looking for the "primary_on_role_change" tag in the DCS
primary_on_role_change=$(patronictl show-config | /opt/cpm/bin/yq r - tags.primary_on_role_change)
            
# if configured to reinit a replica when a "start failed" state is detected, and if a backup
# is not current in progress following a failover, then reinitialize the replica by calling
# the "reinitialize" endpoint on the local Patroni node
if [[ "${primary_on_role_change}" != "true" ]] && 
    check_node_status_and_role "${PATRONI_NAME}" "start failed" "replica"
then
    # reinitialize the local Patroni node
    patronictl reinit "${PATRONI_SCOPE}" "${HOSTNAME}" --force
fi

# always exit with exit code 0 to prevent restarts
exit 0
