#!/bin/bash

# Setting default values 
ACTION="${1:-start}"
BASE_DIR="${2:-../}"
CLUSTER="${3:-platform}"
NAMESPACE="${4:-models}"
IMAGE_REPO="model-api"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/models"

source "$BASE_DIR/scripts/common_functions.sh"

install() {
    local dir=$1
    local namespace=$2

    kubectl apply  -f "$DIR/service.yaml" \
    -f "$DIR/deployment.yaml" \
    -n "$namespace"
}

start() {
    create_namespace "$NAMESPACE"
    # Build custom image and load it into the cluster
    build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER" 

    install "$DIR" "$NAMESPACE"
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