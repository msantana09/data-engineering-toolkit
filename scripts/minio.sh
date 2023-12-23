#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/_entry.sh" "$@"
source "$SCRIPT_DIR/common_functions.sh"

APP="minio"
DIR="$BASE_DIR/services/$APP"
MANIFESTS_DIR="$DIR/manifests"
CHARTS_DIR="$DIR/charts"
NAMESPACE="minio"
IMAGE_REPO_MC="custom-minio-mc"
IMAGE_TAG_MC="latest"


start() {
    local app="minio"
    local env_file="$DIR/.env.$app"

    kubectl apply -f "$MANIFESTS_DIR/namespace.yaml" 
    create_kubernetes_secret "env-secrets" "$NAMESPACE"  "--from-env-file=$DIR/.env"

    # Build custom Minio client image and load it into the cluster
    if ! build_and_load_image "$DIR" "$IMAGE_REPO_MC" "$IMAGE_TAG_MC" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi 

    # Apply manifests
    kubectl apply -f "$MANIFESTS_DIR/minio-server.yaml" 
}

shutdown() { 
    kubectl delete namespace "$NAMESPACE"
}

init(){
    create_env_file "$DIR/.env"   "$DIR/.env-template"
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