#!/bin/bash

source scripts/common_functions.sh

# Required CLI tools
REQUIRED_TOOLS=("realpath" "helm" "kubectl" "docker") 
check_requirements "${REQUIRED_TOOLS[@]}"


# Determine the base directory of the script
SCRIPT_PATH="$(realpath "$0")"
BASE_DIR="$(dirname "$SCRIPT_PATH")"

# Setting default values for arguments

ACTION="start"
CLUSTER="platform"
AIRFLOW_NAMESPACE="airflow"
AIRFLOW_VERSION="2.7.3"
AIRFLOW_IMAGE_REPO="custom-airflow"
AIRFLOW_IMAGE_TAG="latest"
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
        *)
            echo "Error: Invalid argument $1"
            exit 1
            ;;
    esac
done


# Start function
start(){
    echo "Starting $CLUSTER..."

    create_kind_cluster "$CLUSTER" "$BASE_DIR/infra/kind/kind-config.yaml"

    # Apply ingress controller and wait for pods to be running
    kubectl apply -f $BASE_DIR/infra/nginx/ingress-kind-nginx.yaml
    wait_for_container_startup ingress-nginx ingress-nginx app.kubernetes.io/component=controller
    create_env_file "$BASE_DIR/services/storage/.env"   "$BASE_DIR/services/storage/.env.template"
    docker compose -f "$BASE_DIR/services/storage/docker-compose.yaml" up -d minio mc-datalake-init-job

    # install airflow
    AIRFLOW_SCRIPT="$BASE_DIR/scripts/airflow.sh"
    make_executable_and_run "$AIRFLOW_SCRIPT" "$ACTION" "$BASE_DIR" "$CLUSTER" "$AIRFLOW_NAMESPACE" "$AIRFLOW_VERSION" "$AIRFLOW_IMAGE_REPO" "$AIRFLOW_IMAGE_TAG"
}

# Destroy function
destroy(){
    echo "Destroying $CLUSTER..."

    delete_kind_cluster "$CLUSTER"

    # if DELETE_DATA is true, include the -v flag to delete volumes
    if [[ "$DELETE_DATA" = true ]]; then
        echo "Deleting volumes..."
        docker compose -f "$BASE_DIR/services/storage/docker-compose.yaml" down -v
    else
        echo "Not deleting volumes..."
        docker compose -f "$BASE_DIR/services/storage/docker-compose.yaml" down
    fi
}

# Recreate the platform
recreate(){
    destroy
    start
}

case $ACTION in
    start|destroy|recreate)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac