#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="spark"
SPARK_VERSION="3.5.0"
IMAGE_REPO="custom-spark-python"
IMAGE_TAG="latest"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$SERVICE_DIR/manifests"

start() {
    # Main execution
    create_namespace "$SERVICE"

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$SERVICE_DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    # Apply roles
    kubectl apply -f "$MANIFESTS_DIR/roles.yaml" 
}

# stop function
stop() {
    delete_namespace "$SERVICE"
}

init(){
    # nothing to do
    echo ""
}   

# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"