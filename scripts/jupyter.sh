#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/_entry.sh" "$@"
source "$SCRIPT_DIR/common_functions.sh"

NAMESPACE="jupyter"
IMAGE_REPO="custom-spark-jupyter"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/jupyter"
MANIFESTS_DIR="$DIR/manifests"


start() {
   
    create_namespace "$NAMESPACE"
    create_kubernetes_secret "env-secrets" "$NAMESPACE"  "--from-env-file=$DIR/.env"

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    # Apply manifests
    kubectl apply -f "$MANIFESTS_DIR/volumes.yaml" \
        -f "$MANIFESTS_DIR/deployment.yaml" \
        -f "$MANIFESTS_DIR/service.yaml" \
        -f "$MANIFESTS_DIR/roles.yaml" 

    # Wait for container startup
    wait_for_container_startup "$NAMESPACE" jupyter app=jupyter
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"
}

init(){
    create_env_file "$DIR/.env"  "$DIR/.env-template"
}

# Main execution
case $ACTION in
    init|start|shutdown)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac