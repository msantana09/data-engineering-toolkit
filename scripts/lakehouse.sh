#!/bin/bash

services=("minio" "hive" "trino" "kubernetes-dashboard")

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

delete_data_option=""

if [[ "$ACTION" == "stop" ]] && [[ "$DELETE_DATA" == true ]]; then
    delete_data_option="--delete-data"
fi

for service in "${services[@]}"; do
    script=("$BASE_DIR/scripts/$service.sh")

    run_script "$script" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
done