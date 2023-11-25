#!/bin/bash

source scripts/common_functions.sh

# Required CLI tools
REQUIRED_TOOLS=("realpath" "helm" "kubectl" "docker") 
check_requirements "${REQUIRED_TOOLS[@]}"


# Determine the base directory of the script
SCRIPT_PATH="$(realpath "$0")"
BASE_DIR="$(dirname "$SCRIPT_PATH")"

# Setting default values for arguments
ACTION="${1:-start}"
CLUSTER="platform"
AIRFLOW_NAMESPACE="airflow"
AIRFLOW_VERSION="2.7.3"
AIRFLOW_IMAGE_REPO="custom-airflow"
AIRFLOW_IMAGE_TAG="latest"
DELETE_DATA=false

# Define the paths for the scripts to be executed
CLUSTER_SCRIPT="$BASE_DIR/scripts/cluster.sh"
AIRFLOW_SCRIPT="$BASE_DIR/scripts/airflow.sh"

# Start function
start(){
    echo "Starting $CLUSTER..."

    create_kind_cluster "$CLUSTER" "$BASE_DIR/infra/kind/kind-config.yaml"

    # Apply ingress controller and wait for pods to be running
    kubectl apply -f $BASE_DIR/infra/nginx/ingress-kind-nginx.yaml
    wait_for_container_startup ingress-nginx ingress-nginx app.kubernetes.io/component=controller
    create_env_file "$BASE_DIR/services/storage/.env"   "$BASE_DIR/services/storage/.env-template"
    docker compose -f "$BASE_DIR/services/storage/docker-compose.yaml" up -d minio mc-datalake-init-job


    # install airflow
    make_executable_and_run "$AIRFLOW_SCRIPT" "$ACTION" "$BASE_DIR" "$CLUSTER" "$AIRFLOW_NAMESPACE" "$AIRFLOW_VERSION" "$AIRFLOW_IMAGE_REPO" "$AIRFLOW_IMAGE_TAG"
}

# Destroy function
destroy(){
    echo "Destroying $CLUSTER..."

    #make_executable_and_run "$CLUSTER_SCRIPT" "$ACTION" "$BASE_DIR" "$CLUSTER" "$DELETE_DATA"
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

# Recreate function
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