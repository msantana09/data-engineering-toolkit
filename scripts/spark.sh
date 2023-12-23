#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/_entry.sh" "$@"
source "$SCRIPT_DIR/common_functions.sh"

NAMESPACE="spark"
SPARK_VERSION="3.5.0"
IMAGE_REPO="custom-spark-python"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/spark"
MANIFESTS_DIR="$DIR/manifests"

start() {
    # Main execution
    create_namespace "$NAMESPACE"

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    # Apply roles
    kubectl apply -f "$MANIFESTS_DIR/roles.yaml" 
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"
}

init(){
    # nothing to do
    echo ""
}   

# Main execution
case $ACTION in
    start|init|shutdown)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac