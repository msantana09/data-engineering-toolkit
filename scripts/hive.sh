#!/bin/bash

# Setting default values 
ACTION="${1:-start}"
BASE_DIR="${2:-../}"
CLUSTER="${3:-platform}"
NAMESPACE="${4:-hive}"

IMAGE_REPO="custom-apache-hive"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/hive"

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
    create_namespace "$NAMESPACE"

    create_hive_secret "$NAMESPACE" "$DIR/.env"

    # Build custom image and load it into the cluster
    build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER" 

    if ! docker-compose -f "$BASE_DIR/services/storage/docker-compose.yaml" up -d hive-metastore-postgres ; then
        echo "Failed to start Hive's Postgres Database with docker-compose"
        exit 1
    fi 

    kubectl apply -f "$DIR/configMap.yaml" \
    -f "$DIR/service.yaml" \
    -f "$DIR/deployment.yaml"

    wait_for_container_startup "$NAMESPACE"  hive-metastore app=hive-metastore
}

# Destroy function
destroy() {
    kubectl delete namespace "$NAMESPACE"
}

# Main execution
case $ACTION in
    start|destroy)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac