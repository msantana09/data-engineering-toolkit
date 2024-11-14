#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="hive"
IMAGE_REPO="custom-apache-hive"
IMAGE_TAG="latest"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$SERVICE_DIR/manifests"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-$SERVICE.yaml"


start() {
    create_namespace "$SERVICE"    
    
    local env_file="$SERVICE_DIR/.env"
    create_kubernetes_secret "hive-secrets" "$SERVICE" "--from-env-file=$env_file" 

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$SERVICE_DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    if ! docker compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Hive's Postgres Database with docker-compose"
        exit 1
    fi 
    
    sleep 5;
    
    kubectl apply -f "$MANIFESTS_DIR/configMap.yaml" \
    -f "$MANIFESTS_DIR/service.yaml" \
    -f "$MANIFESTS_DIR/deployment.yaml"

    wait_for_container_startup "$SERVICE"  hive-metastore app=hive-metastore

    # check if hive has started already
    if ! kubectl -n hive logs "$(kubectl -n hive get pods -l app=hive-metastore -o jsonpath='{.items[0].metadata.name}')" | grep  "Starting Hive Metastore Server" &> /dev/null ; then
        # tail the logs of the container with label app=hive-metastore in the namespace hive, 
        # and exit once the string "Starting Hive Metastore Server" is found.
        echo "Waiting for Hive initialization to complete..."
        kubectl -n hive logs -f "$(kubectl -n hive get pods -l app=hive-metastore -o jsonpath='{.items[0].metadata.name}')" | grep -q "Starting Hive Metastore Server"
    fi
}

# stop function
stop() {

    local env_file="$STORAGE_DIR/.env.$SERVICE"
    delete_namespace "$SERVICE"

    stop_docker_compose_stack "$SERVICE" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"
}

init(){
    create_env_file "$SERVICE_DIR/.env"  "$SERVICE_DIR/.env-template"
    create_env_file "$STORAGE_DIR/.env.hive"  "$STORAGE_DIR/.env-hive-template"
}

# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"