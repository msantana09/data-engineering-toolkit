#!/bin/bash

# Check if realpath command exists
if ! command -v realpath &> /dev/null; then
    echo "Error: realpath command not found."
    exit 1
fi

# Determine the base directory of the script
SCRIPT_PATH="$(realpath "$0")"
BASE_DIR="$(dirname "$SCRIPT_PATH")"

# Setting default values for arguments
CLUSTER="${1:-platform}"
AIRFLOW_NAMESPACE="${2:-airflow}"
AIRFLOW_VERSION="${3:-2.7.3}"
AIRFLOW_IMAGE_REPO="${4:-custom-airflow}"
AIRFLOW_IMAGE_TAG="${5:-latest}"

# Define the paths for the scripts to be executed
CREATE_CLUSTER_SCRIPT="$BASE_DIR/scripts/create_cluster.sh"
DEPLOY_AIRFLOW_SCRIPT="$BASE_DIR/scripts/deploy_airflow.sh"

# Function to make script executable if not already
make_executable_and_run() {
    local script_path=$1

    if [[ ! -f "$script_path" ]]; then
        echo "Error: Script $script_path not found."
        exit 1
    fi

    if [[ ! -x "$script_path" ]]; then
        echo "Making script $script_path executable."
        chmod +x "$script_path"
    fi

    # Execute the script with the remaining arguments
    "$script_path" "${@:2}"
}

# Execute the scripts
make_executable_and_run "$CREATE_CLUSTER_SCRIPT" "$BASE_DIR" "$CLUSTER"
make_executable_and_run "$DEPLOY_AIRFLOW_SCRIPT" "$BASE_DIR" "$CLUSTER" "$AIRFLOW_NAMESPACE" "$AIRFLOW_VERSION" "$AIRFLOW_IMAGE_REPO" "$AIRFLOW_IMAGE_TAG"
