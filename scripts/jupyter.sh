#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="jupyter"
IMAGE_REPO="custom-spark-jupyter"
IMAGE_TAG="latest"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$SERVICE_DIR/manifests"


start() {
   
    create_namespace "$SERVICE"
    create_kubernetes_secret "env-secrets" "$SERVICE"  "--from-env-file=$SERVICE_DIR/.env"

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$SERVICE_DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    # Apply manifests
    kubectl apply -f "$MANIFESTS_DIR/volumes.yaml" \
        -f "$MANIFESTS_DIR/deployment.yaml" \
        -f "$MANIFESTS_DIR/service.yaml" \
        -f "$MANIFESTS_DIR/roles.yaml" 

    # Wait for container startup
    wait_for_container_startup "$SERVICE" jupyter app=jupyter
}

# shutdown function
shutdown() {
    delete_namespace "$SERVICE"

    delete_pvs "app=jupyter" 
}

init(){
    create_env_file "$SERVICE_DIR/.env"  "$SERVICE_DIR/.env-template"
}

# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"