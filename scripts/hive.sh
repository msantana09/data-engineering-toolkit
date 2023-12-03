#!/bin/bash

# Setting default values 
ACTION="start"
CLUSTER="platform"
DELETE_DATA=false
BASE_DIR=".."

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -b|--base_dir)
            BASE_DIR="$2"
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

NAMESPACE="hive"
IMAGE_REPO="custom-apache-hive"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/hive"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-hive.yaml"

source "$BASE_DIR/scripts/common_functions.sh"

create_hive_secret() {
    local namespace=$1
    local env_file=$2

    # not using create_kubernetes_secret function because of the hyphens in values
    # is being interpreted as flags
    kubectl create secret generic "hive-secrets"  -n "$namespace" \
       "--from-env-file=$env_file" 

}

start() {
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$STORAGE_DIR/.env.hive"  "$STORAGE_DIR/.env-hive-template"

    create_namespace "$NAMESPACE"

    create_hive_secret "$NAMESPACE" "$DIR/.env"

    # Build custom image and load it into the cluster
    build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER" 

    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Hive's Postgres Database with docker-compose"
        exit 1
    fi 

    kubectl apply -f "$DIR/configMap.yaml" \
    -f "$DIR/service.yaml" \
    -f "$DIR/deployment.yaml"

    wait_for_container_startup "$NAMESPACE"  hive-metastore app=hive-metastore
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"

    local app="hive"
    local env_file="$STORAGE_DIR/.env.$app"

    shutdown_storage "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"

}

# Main execution
case $ACTION in
    start|shutdown)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac