#!/bin/bash
source scripts/common_functions.sh

# Required CLI tools
REQUIRED_TOOLS=("realpath" "helm" "kubectl" "docker") 
check_requirements "${REQUIRED_TOOLS[@]}"
# check if docker is running, else start it
if ! docker info >/dev/null 2>&1; then
    echo "ERROR::: Docker is not running.  Please start docker and try again."
    exit 1
fi

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
            echo "  <action>                      The action to perform"
            echo "  -c, --cluster <cluster_name>  Set the cluster name (default: platform)"
            echo "  -d, --delete-data             Delete data (default: false)"
            echo "  -h, --help                    Display this help message"
            echo "  [sub_scripts...]              Additional scripts to run (default: core). Valid names are: airflow, datahub, hive, jupyter, minio, models, trino, spark, superset, lakehouse (minio, hive, trino ), core(lakehouse + airflow + spark)"
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
    app="$1"
    delete_data_option=""
    
    if [[ "$ACTION" == "shutdown" ]] && [[ "$DELETE_DATA" == true ]]; then
        delete_data_option="--delete-data"
    fi


    case "$app" in
    "minio"|"hive"|"trino"|"airflow"|"spark"|"models"|"superset"|"datahub"|"jupyter"|"kafka")
        # Run the corresponding script
        SCRIPT="$BASE_DIR/scripts/$app.sh"
        echo "Running $SCRIPT..."
        make_executable_and_run "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
        ;;
    "core")
        # basically airflow and dependencies
        for CORE_SCRIPT in "minio" "hive" "trino" "airflow" "spark"
        do
            SCRIPT="$BASE_DIR/scripts/$CORE_SCRIPT.sh"
            echo "Running $SCRIPT..."
            make_executable_and_run "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
        done
        ;;
    "lakehouse")
        for CORE_SCRIPT in "minio" "hive" "trino" 
        do
            SCRIPT="$BASE_DIR/scripts/$CORE_SCRIPT.sh"
            echo "Running $SCRIPT..."
            make_executable_and_run "$SCRIPT" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
        done
        ;;
    *)
        # Print an error message
        echo "Invalid sub-script name: $app"
        echo " Valid names are: airflow, datahub, hive, jupyter, kafka, minio, models, trino, spark, superset, lakehouse (minio, hive, trino), core (lakehouse + airflow + spark)"
        ;;
    esac

}

create_local_registry(){
    # 1. Create registry container unless it already exists
    reg_name='kind-registry'
    reg_port='5001'
    if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
    docker run \
        -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network bridge --name "${reg_name}" \
        registry:2
    fi
}

finish_local_registry_setup(){
    reg_port='5001'
    # 3. Add the registry config to the nodes
    #
    # This is necessary because localhost resolves to loopback addresses that are
    # network-namespace local.
    # In other words: localhost in the container is not localhost on the host.
    #
    # We want a consistent name that works from both ends, so we tell containerd to
    # alias localhost:${reg_port} to the registry container when pulling images
    REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
    for node in $(kind get nodes --name platform); do
    docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
    cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
    [host."http://${reg_name}:5000"]
EOF
    done

    # 4. Connect the registry to the cluster network if not already connected
    # This allows kind to bootstrap the network but ensures they're on the same network
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
    docker network connect "kind" "${reg_name}"
    fi

    # 5. Document the local registry
    # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    kubectl apply -f "$BASE_DIR/infra/kind/local-registry-config.yaml"
}

# Start function
start(){
    create_local_registry

    echo "Starting $CLUSTER..."

    create_kind_cluster "$CLUSTER" "$BASE_DIR/infra/kind/kind-config.yaml"

    finish_local_registry_setup

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
                    shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$STORAGE_DIR/docker-compose-$app.yaml"
                fi
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
    for app in "airflow" "datahub" "hive" "jupyter" "models" "trino" "superset" "kafka" "minio"
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
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac