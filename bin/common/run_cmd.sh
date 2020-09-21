#!/bin/bash

if [[ "${ASYNC}" == "true" ]]
then
    socat_args+=("-T 90")
fi

cmd_arr=("$@")
cmd="${cmd_arr[0]}"

printf "running command '%s' (pid=%s)\n" "${cmd}" "$$"
while read -r line
do
    if [[ "${ASYNC}" != "true" && "${line:0:9}" == "EXIT_CODE" ]]
    then
        line_arr=(${line})
        exit_code=${line_arr[1]}
        printf "EXIT_CODE %s (pid=%s)\n" "${exit_code}" "$$"
    fi
    printf "%s\n" "${line}"
done < <(echo "$(printf "%q " "$@")" | socat ${socat_args[*]} "/crunchyadm/${SOCKET}.sock" "-,ignoreeof")
printf "command '%s' complete (pid=%s)\n" "${cmd}" "$$"
exit "${exit_code}"

# run_cmd() {
#     cmd_arr=("$@")
#     cmd="${cmd_arr[0]}"
#     printf "executing '%s' in sidecar (pid=%s)\n" "${cmd}" "$$"
#     while read -r line
#     do
#         if [[  "${line:0:9}" == "EXIT_CODE" ]]
#         then
#             line_arr=(${line})
#             exit_code=${line_arr[1]}
#             printf "EXIT_CODE (pid=%s): %s\n" "$$" "${exit_code}"
#             exit "${exit_code}"
#         fi
#         printf "%s\n" "${line}"
#     done < <(echo "$(printf "%q " "$@")" | socat -t /crunchyadm/pgo.sock -,ignoreeof)
#     printf "finished executing '%s' in sidecar (pid=%s)\n" "${cmd}" "$$"
# }

# function to run a remote command that does not wait for an exit code
# run_cmd_asynchronus() {
#     cmd_arr=("$@")
#     cmd="${cmd_arr[0]}"
#     printf "executing '%s' in sidecar (pid=%s)\n" "${cmd}" "$$"
#     while read -r line
#     do
#         printf "%s\n" "${line}"
#     done < <(echo "$(printf "%q " "$@")" | socat -t 2 "/crunchyadm/${SOCKET}.sock" -)
#     printf "finished executing '%s' in sidecar (pid=%s)\n" "${cmd}" "$$"
# }

# function to run a remote command and wait for an exit code
# run_cmd_synchronus() {
#     cmd_arr=("$@")
#     cmd="${cmd_arr[0]}"
#     printf "running command '%s' (pid=%s)\n" "$@" "$$"
#     while read -r line
#     do
#         if [[ "${line:0:9}" == "EXIT_CODE" ]]
#         then
#             line_arr=(${line})
#             exit_code=${line_arr[1]}
#             printf "EXIT_CODE %s (pid=%s)\n" "${exit_code}" "$$"
#             exit "${exit_code}"
#         fi
#         printf "%s\n" "${line}"
#     done < <(echo "$(printf "%q " "$@")" | socat "/crunchyadm/${SOCKET}.sock" -,ignoreeof)
#     printf "command '%s' complete (pid=%s)\n" "$@" "$$"
# }

# if [[ "${ASYNC}" != "true" ]]
# then
#     run_cmd_synchronus "$@"
# else
#     run_cmd_asynchronus "$@"
# fi
