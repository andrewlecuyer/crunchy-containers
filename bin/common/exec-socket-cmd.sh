#!/bin/bash

read -r cmd
printf "starting command in sidecar: '%s'\n" "${cmd}"
cmd_arr=(${cmd})
exe=${cmd_arr[0]}
# eval "${cmd}"
# printf "EXIT_CODE %s\n" "$?"

case "${exe}" in
    
    # "initdb" | "pg_controldata" | "pg_ctl" | "pg_isready" | "postgres" | "psql")
    #     eval "${cmd}"
    #     printf "EXIT_CODE %s\n" "$?"
    #     ;;

    "pgbackrest")
        source "/crunchyadm/pgbackrest_env.sh"
        cd "${PGBACKREST_PG1_PATH}" || exit
        eval "${cmd}"
        printf "EXIT_CODE %s\n" "$?"
        ;;

    # "postgres")
    #     source "/crunchyadm/pgbackrest_env.sh"
    #     eval "${cmd}"
    #     printf "EXIT_CODE %s\n" "$?"
    #     ;;

    *)
        eval "${cmd}"
        printf "EXIT_CODE %s\n" "$?"
        ;;

esac


# while true; do printf '%b' '\0'; sleep 0.5; done &
# backgroud_pid=$!
# echo "background pid is $backgroud_pid"

    # "postgres")
    #     (${cmd} &) & 
    #     ;;

# case "${exe}" in
    
#     "initdb" | "pg_controldata" | "pg_ctl" | "pg_isready")
#         eval "${cmd}"
#         exit_code=$?
#         ;;

#     "postgres")
#         # ( eval "${cmd}" & )
#         # { eval "${cmd}" & } &
#         echo "exec ONE"
#         (${cmd} &) & 
#         pid=$!
#         echo "exec TWO: $pid"
#         while [[ -e "/proc/${pid}" ]] && ! pg_isready -h /crunchyadm
#         do
#             echo "exec THREE: $pid"
#             sleep 0.5
#         done
#         echo "exec FOUR: $pid"
#         if [[ -e "/proc/${pid}" ]]
#         then
#             echo "exec FIVE: $pid"
#             exit_code=0
#         else
#             echo "exec SIX: $pid"
#             wait "${pid}"
#             echo "exec SEVEN: $pid"
#             exit_code=$?
#             echo "exec EIGHT: $exit_code"
#         fi
#         #disown "${pid}"
#         ;;

#     *)
#         echo "command not recognized, exiting"
#         exit 1
#         ;;
# esac

# printf "EXIT_CODE %s\n" "${exit_code}"
# kill "${backgroud_pid}"
# echo "exec NINE"

# while true; do printf '%b' '\0'; sleep 0.5; done &
# backgroud_pid=$!
# echo "background pid is $backgroud_pid"

# read -r cmd
# printf "executing sidecar command '%s'\n" "${cmd}"
# eval "${cmd}"
# echo "finished executing sidecar command"

# echo "about to kill background pid $backgroud_pid"
# kill $!
# echo "killed background pid $backgroud_pid"

# read -r cmd
# printf "executing sidecar command '%s'\n" "${cmd}"
# eval "${cmd}"
# pid=$!
# echo "PID is $pid"
# while [ -e /proc/$pid ]; do
#     printf '%b' '\0'
# done
