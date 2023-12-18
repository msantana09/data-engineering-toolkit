#!/bin/bash

# Setting default values 
if [[ $# -gt 0 ]]; then
    ACTION="$1"
    shift
fi
CLUSTER="platform"
DELETE_DATA=false
BASE_DIR=".."

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

NAMESPACE="spark"
SPARK_VERSION="3.5.0"
IMAGE_REPO="custom-spark-python"
IMAGE_TAG="latest"

DIR="$BASE_DIR/services/spark"
CHARTS_DIR="$DIR/charts"

source "$BASE_DIR/scripts/common_functions.sh"

start() {
    # Main execution
    create_namespace "$NAMESPACE"

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    # Apply roles
    kubectl apply -f "$CHARTS_DIR/roles.yaml" 
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"
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