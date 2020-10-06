#!/bin/bash

# source /opt/cpm/bin/common/run_cmd.sh
# run_cmd_synchronus "/proc/$$/root/opt/cpm/bin/bootstrap/post-bootstrap.sh" "$$"

SOCKET=crunchy-pg ASYNC=false /opt/cpm/bin/common/run_cmd.sh \
    "/proc/$$/root/$1" "$$"
