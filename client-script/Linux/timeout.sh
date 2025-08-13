#!/bin/bash

timeout() {
    local seconds=$1
    shift

    "$@" &
    local pid=$!

    ( sleep "${seconds}" && kill -TERM "${pid}" ) 2>/dev/null &
    local alarm_pid=$!

    wait "${pid}" 2>/dev/null
    local exit_code=$?

    kill -TERM "${alarm_pid}" 2>/dev/null

    case $exit_code in
        0)   return 0   ;;  # Success
        143) return 124 ;;  # Timeout (kill SIGTERM 128+15)
        *)   return $exit_code ;;
    esac
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <time> <command>"
    exit 1
elif ! [[ $1 =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid time format. Please provide a positive integer."
    exit 1
fi

timeout "$@"
