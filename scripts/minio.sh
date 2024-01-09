#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="minio"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$SERVICE_DIR/manifests"
CHARTS_DIR="$SERVICE_DIR/charts"
IMAGE_REPO_MC="custom-minio-mc"
IMAGE_TAG_MC="latest"


start() {
   
    kubectl apply -f "$MANIFESTS_DIR/namespace.yaml" 
    create_kubernetes_secret "env-secrets" "$SERVICE"  "--from-env-file=$SERVICE_DIR/.env"

    # Build custom Minio client image and load it into the cluster
    if ! build_and_load_image "$SERVICE_DIR" "$IMAGE_REPO_MC" "$IMAGE_TAG_MC" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi 

    # Apply manifests
    kubectl apply -f "$MANIFESTS_DIR/minio-server.yaml" 
}

shutdown() { 
    delete_namespace "$SERVICE"

    # delete data directory
    if  [[ "$DELETE_DATA" == true ]]; then
        find $SERVICE_DIR/data -mindepth 1 -exec rm -rf {} +
    fi
}

init(){
    create_env_file "$SERVICE_DIR/.env"   "$SERVICE_DIR/.env-template"
    # create data directory if it doesn't exist 
    mkdir -p "$SERVICE_DIR/data"
}


# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"