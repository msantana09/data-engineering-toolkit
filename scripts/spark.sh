#!/bin/bash

# Setting default values 
ACTION="${1:-start}"
BASE_DIR="${2:-../}"
CLUSTER="${3:-platform}"
NAMESPACE="${4:-spark}"
SPARK_VERSION="${5:-3.5.0}"
IMAGE_REPO="${6:-custom-spark-python}"
IMAGE_TAG="${7:-latest}"



SPARK_DIR="$BASE_DIR/services/spark"

source "$BASE_DIR/scripts/common_functions.sh"

start() {
    # Main execution
    create_namespace "$NAMESPACE"

    # Build custom image and load it into the cluster
    build_and_load_image "$SPARK_DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER" 

    # Apply roles
    kubectl apply -f "$SPARK_DIR/roles.yaml" 
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