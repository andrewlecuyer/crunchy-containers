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

# Set the PATRONI_NAME environment variable
export $(get_patroni_name)

# While the local instance is initializing, readiness is determined based on whether or not the
# 'pgha_initialized' file exists.  Therefore, if this file does not yet exist, then the instance
# has not yet been initialized (i.e. it is not yet ready), and we can simply exit.
if [[ ! -f "/crunchyadm/pgha_initialized" ]]
then
    # return exit code 1 if not initialized
    exit 1
fi
    
# Determine readiness by checking whether or not the local instance has a "running" status
check_node_status_and_role "${PATRONI_NAME}" "running"
