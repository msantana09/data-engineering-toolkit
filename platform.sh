#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
BASE_DIR="$(dirname "$SCRIPT_PATH")"
source "$BASE_DIR/scripts/helper_functions/common.sh"
source "$BASE_DIR/scripts/helper_functions/registry.sh"

# Required CLI tools
REQUIRED_TOOLS=("realpath" "helm" "kubectl" "docker") 
check_requirements "${REQUIRED_TOOLS[@]}"

# check if docker is running, else start it
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running.  Please start docker and try again."
    exit 1
fi

# Determine the base directory of the script
STORAGE_DIR="$BASE_DIR/services/storage"
ACTION=""
SUB_SCRIPTS=()
CLUSTER="platform"
DELETE_DATA=false

apps=($(get_apps "$BASE_DIR/scripts"))

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 <action> [-c|--cluster <cluster_name>] [-d|--delete-data] [sub_scripts...]"
            echo ""
            echo "Options:"
            echo "  <action>                      The action to perform (init|start|stop|recreate)"
            echo "  -c, --cluster <cluster_name>  Set the cluster name (default: platform)"
            echo "  -d, --delete-data             Delete data flag (default: false)"
            echo "  -h, --help                    Display this help message"
            echo "  [sub_scripts...]              Additional scripts to run (default: core). "
            echo "                                Valid names include: "
            echo "                                  airflow, datahub, hive, jupyter, kafka, kubernetes-dashboard, minio, models, trino, spark,"
            echo "                                  lakehouse (minio, hive, trino),"
            echo "                                  core (lakehouse + airflow + spark + kafka)"
            exit 0
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
            # If ACTION is not set, set it. Otherwise, assume any other argument is a sub-script
            if [ -z "$ACTION" ]; then
                ACTION="$1"
            else
                SUB_SCRIPTS+=("$1")
            fi
            shift
            ;;
    esac
done

# if SUB_SCRIPTS is empty and ACTION==start, default SUB_SCRIPTS to 'core'
if [[ ${#SUB_SCRIPTS[@]} -eq 0 ]] && [[ "$ACTION" == "start" ]]; then
    echo 'No sub-scripts specified. Defaulting to "core".'
    SUB_SCRIPTS=("core")
fi


run_app_subscript(){
    local app="$1"
    local delete_data_option=$2
    local script_to_run=""

    # if delete_data_option is not set, set it to ""
    if [[ -z "$delete_data_option" ]]; then
        delete_data_option=""
    fi   

    # check if app is in the list of apps
    if [[ " ${apps[@]} " =~ " ${app} " ]]; then
        script_to_run="$BASE_DIR/scripts/$app.sh"
    fi

    # if script_to_run is not empty, run it
    if [[ -n "$script_to_run" ]]; then
        run_script "$script_to_run" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
    else
        echo "Error: Invalid app name - $app"
        exit 1
    fi
}

# Start function
start(){
    start_local_registry

    echo "Starting $CLUSTER..."
    create_kind_cluster "$CLUSTER" "$BASE_DIR/cluster/kind/kind-config.yaml"

    # Set the context to the cluster
    # this should already be set by create_kind_cluster through kind, but just in case
    kubectl config use-context "kind-$CLUSTER"

    # updating containerd config
    finish_local_registry_setup "$BASE_DIR"

    # Apply ingress controller and wait for pods to be running
    kubectl apply -f $BASE_DIR/cluster/nginx/ingress-kind-nginx.yaml
    wait_for_container_startup ingress-nginx ingress-nginx app.kubernetes.io/component=controller

    echo  "${SUB_SCRIPTS[@]}"
    for SUB_SCRIPT in "${SUB_SCRIPTS[@]}"
    do
        echo "Starting $SUB_SCRIPT..."
        # Run the corresponding script
        run_app_subscript "$SUB_SCRIPT"
    done
}

# Stop function
stop(){
    local delete_data_option=""    
    if [[ "$DELETE_DATA" == true ]]; then
        delete_data_option="--delete-data"
    fi

    # Set the context to the cluster
    # this should already be set by create_kind_cluster through kind, but just in case
    kubectl config use-context "kind-$CLUSTER"

    if [[ ${#SUB_SCRIPTS[@]} -eq 0 ]]; then
        # No sub-scripts specified, shut down everything        
        echo "Shutting down $CLUSTER..."

        if [[ "$DELETE_DATA" == true ]]; then
            # Delete local storage
            run_app_subscript "minio" "$delete_data_option"
            run_app_subscript "kafka" "$delete_data_option"
        fi

        # Delete cluster container      
        delete_kind_cluster "$CLUSTER" 

        # shut down local registry
        stop_local_registry "$DELETE_DATA"

        # stop all storage services outside cluster (docker compose)
        stop_running_storage_containers "$STORAGE_DIR" "$DELETE_DATA"
    else
        # stop only the specified services
        echo "Stopping down ${SUB_SCRIPTS[@]}..."
        for SUB_SCRIPT in "${SUB_SCRIPTS[@]}"
        do
            run_app_subscript "$SUB_SCRIPT" "$delete_data_option"
        done
    fi
}

# Recreate the platform
recreate(){
    stop
    start
}

# create .env files if they doesn't exist
init(){
    # ACTION="init"
    # update to iterate through all apps
    for app in "${apps[@]}"
    do        
        printf "\n###### Initializing $app .env files\n"
        SCRIPT="$BASE_DIR/scripts/$app.sh"
        run_script "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER"
    done
}

case $ACTION in
    init|start|stop|recreate)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"        exit 1
        ;;
esac