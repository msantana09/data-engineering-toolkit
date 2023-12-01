#!/bin/bash

# Setting default values 
ACTION="${1:-start}"
BASE_DIR="${2:-../}"
CLUSTER="${3:-platform}"
NAMESPACE="${4:-superset}"
IMAGE_REPO="superset"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/superset"

source "$BASE_DIR/scripts/common_functions.sh"

install() {
    local dir=$1
    local namespace=$2
    if ! helm upgrade --install superset superset/superset\
        --namespace "$namespace" \
        --values "$dir/values.yaml"; then
        echo "Failed to install/upgrade Superset"
        exit 1
    fi
}

start() {
    create_namespace "$NAMESPACE"
    # Build custom image and load it into the cluster
    #build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER" 
    if ! docker-compose -f "$BASE_DIR/services/storage/docker-compose.yaml" up -d superset-postgres ; then
        echo "Failed to start Superset's Postgres Database with docker-compose"
        exit 1
    fi 

    helm repo add superset https://apache.github.io/superset
    helm repo update



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