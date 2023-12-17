#!/bin/bash

source scripts/common_functions.sh

# Required CLI tools
REQUIRED_TOOLS=("realpath" "helm" "kubectl" "docker") 
check_requirements "${REQUIRED_TOOLS[@]}"


# Determine the base directory of the script
SCRIPT_PATH="$(realpath "$0")"
BASE_DIR="$(dirname "$SCRIPT_PATH")"
STORAGE_DIR="$BASE_DIR/services/storage"

# Setting default values for arguments

ACTION="start"
CLUSTER="platform"
DELETE_DATA=false

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER="$2"
            shift 2
            ;;
        -d|--delete-data)
            DELETE_DATA=true
            shift
            ;;
        --) 
            shift
            break
            ;;
        *)
            # Assume any other argument is a sub-script
            SUB_SCRIPTS+=("$1")
            shift
            ;;
    esac
done

# if SUB_SCRIPTS is empty, default it to 'core'
if [[ ${#SUB_SCRIPTS[@]} -eq 0 ]]; then
    SUB_SCRIPTS=("core")
fi


# Start function
start(){
    echo "Starting $CLUSTER..."

    create_kind_cluster "$CLUSTER" "$BASE_DIR/infra/kind/kind-config.yaml"

    # Apply ingress controller and wait for pods to be running
    kubectl apply -f $BASE_DIR/infra/nginx/ingress-kind-nginx.yaml
    wait_for_container_startup ingress-nginx ingress-nginx app.kubernetes.io/component=controller

    for SUB_SCRIPT in "${SUB_SCRIPTS[@]}"
    do
        # Check if the sub-script name is valid
        case "$SUB_SCRIPT" in
        "hive"|"trino"|"airflow"|"spark"|"models"|"superset"|"datahub"|"jupyter")
            # Run the corresponding script
            SCRIPT="$BASE_DIR/scripts/$SUB_SCRIPT.sh"
            echo "Running $SCRIPT..."
            make_executable_and_run "$SCRIPT" -a "$ACTION" -b "$BASE_DIR" -c "$CLUSTER"
            ;;
        "core")
            # basically airflow and dependencies
            for CORE_SCRIPT in "minio" "hive" "trino" "airflow" "spark"
            do
                SCRIPT="$BASE_DIR/scripts/$CORE_SCRIPT.sh"
                echo "Running $SCRIPT..."
                make_executable_and_run "$SCRIPT" -a "$ACTION" -b "$BASE_DIR" -c "$CLUSTER"
            done
            ;;
        "lakehouse")
            for CORE_SCRIPT in "minio" "hive" "trino" 
            do
                SCRIPT="$BASE_DIR/scripts/$CORE_SCRIPT.sh"
                echo "Running $SCRIPT..."
                make_executable_and_run "$SCRIPT" -a "$ACTION" -b "$BASE_DIR" -c "$CLUSTER"
            done
            ;;
        *)
            # Print an error message
            echo "Invalid sub-script name: $SUB_SCRIPT"
            echo "Valid names are: hive, trino, airflow, spark, models, superset, datahub, jupyter"
            ;;
        esac
    done
}

# Shutdown function
shutdown(){
    echo "Shutting down $CLUSTER..."
    
    delete_kind_cluster "$CLUSTER"

    for file_path in "$BASE_DIR"/services/storage/*.yaml
    do
        filename="${file_path##*/}"

        # Check if the file name matches the pattern
        if [[ $filename =~ docker-compose-(.*).yaml ]]; then

            # Extract the app name from the file name
            local app="${BASH_REMATCH[1]}"
            local env_file="$STORAGE_DIR/.env.$app"
            # Check if .env file exists 
            if [ -f  "$env_file" ]; then
                shutdown_storage "$app" "$env_file" "$DELETE_DATA" "$STORAGE_DIR/docker-compose-$app.yaml"
            fi
        else
            echo "Pattern not found"
        fi
    done
}

# Recreate the platform
recreate(){
    shutdown
    start
}

case $ACTION in
    start|shutdown|recreate)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac