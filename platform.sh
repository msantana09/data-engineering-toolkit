#!/bin/bash
source scripts/common_functions.sh
source scripts/registry.sh

# Required CLI tools
REQUIRED_TOOLS=("realpath" "helm" "kubectl" "docker") 
check_requirements "${REQUIRED_TOOLS[@]}"

# check if docker is running, else start it
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running.  Please start docker and try again."
    exit 1
fi

apps=("minio" "hive" "trino" "airflow" "spark" "models" "superset" "datahub" "jupyter" "kafka" "kubernetes-dashboard")
core_apps=("minio" "hive" "trino" "airflow" "spark" "kubernetes-dashboard")
lakehouse_apps=("minio" "hive" "trino" "kubernetes-dashboard")

# Determine the base directory of the script
SCRIPT_PATH="$(realpath "$0")"
BASE_DIR="$(dirname "$SCRIPT_PATH")"
STORAGE_DIR="$BASE_DIR/services/storage"
ACTION=""
SUB_SCRIPTS=()
CLUSTER="platform"
DELETE_DATA=false

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 <action> [-c|--cluster <cluster_name>] [-d|--delete-data] [sub_scripts...]"
            echo ""
            echo "Options:"
            echo "  <action>                      The action to perform (init|start|shutdown|recreate)"
            echo "  -c, --cluster <cluster_name>  Set the cluster name (default: platform)"
            echo "  -d, --delete-data             Delete data flag (default: false)"
            echo "  -h, --help                    Display this help message"
            echo "  [sub_scripts...]              Additional scripts to run (default: core). "
            echo "                                Valid names include: "
            echo "                                  airflow, datahub, hive, jupyter, kafka, kubernetes-dashboard, minio, models, trino, spark, superset,"
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
    SUB_SCRIPTS=("core")
fi


call_app_script(){
    local app="$1"
    local delete_data_option=""
    
    if [[ "$ACTION" == "shutdown" ]] && [[ "$DELETE_DATA" == true ]]; then
        delete_data_option="--delete-data"
    fi

    if [[ " ${apps[@]} " =~ " ${app} " ]]; then
        SCRIPT="$BASE_DIR/scripts/$app.sh"
        make_executable_and_run "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
    elif [[ "$app" == "core" ]]; then
        for core_app in "${core_apps[@]}"; do
            SCRIPT="$BASE_DIR/scripts/$core_app.sh"
            make_executable_and_run "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
        done
    elif [[ "$app" == "lakehouse" ]]; then
        for lakehouse_app in "${lakehouse_apps[@]}"; do
            SCRIPT="$BASE_DIR/scripts/$lakehouse_app.sh"
            make_executable_and_run "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
        done
    fi
}

# Start function
start(){
    start_local_registry

    echo "Starting $CLUSTER..."

    create_kind_cluster "$CLUSTER" "$BASE_DIR/infra/kind/kind-config.yaml"
 
    finish_local_registry_setup "$BASE_DIR"

    # Apply ingress controller and wait for pods to be running
    kubectl apply -f $BASE_DIR/infra/nginx/ingress-kind-nginx.yaml
    wait_for_container_startup ingress-nginx ingress-nginx app.kubernetes.io/component=controller

    for SUB_SCRIPT in "${SUB_SCRIPTS[@]}"
    do
        # Run the corresponding script. if it fails, exit
        call_app_script "$SUB_SCRIPT"
    done
}

# Shutdown function
shutdown(){

    if [[ ${#SUB_SCRIPTS[@]} -eq 0 ]]; then
        echo "Shutting down $CLUSTER..."

        # Shutdown all services        
        delete_kind_cluster "$CLUSTER" 

        # shut down local registry
        stop_local_registry

        # Shutdown all storage services outside cluster (docker compose)
        for file_path in "$STORAGE_DIR"/*.yaml
        do
            filename="${file_path##*/}"

            # Check if the file name matches the pattern
            if [[ $filename =~ docker-compose-(.*).yaml ]]; then
                # check if file_path is listed in docker-compose ls output
                if ! docker-compose ls | grep "$file_path" >/dev/null 2>&1; then
                    # skipping if not running
                    continue
                fi

                # check to see if the services in the docker-compose file are running
                # Extract the app name from the file name
                local app="${BASH_REMATCH[1]}"
                local env_file="$STORAGE_DIR/.env.$app"
                # Check if .env file exists 
                if [ ! -f  "$env_file" ]; then
                    env_file=""
                fi
                shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$STORAGE_DIR/docker-compose-$app.yaml"
            else
                echo "Pattern not found"            
            fi
        done
    else
        echo "Shutting down ${SUB_SCRIPTS[@]}..."

        # Shutdown only the specified services
        for SUB_SCRIPT in "${SUB_SCRIPTS[@]}"
        do
            call_app_script "$SUB_SCRIPT"
        done
    fi
}

# Recreate the platform
recreate(){
    shutdown
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
        make_executable_and_run "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER"
    done
}

case $ACTION in
    init|start|shutdown|recreate)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"        exit 1
        ;;
esac