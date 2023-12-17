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


NAMESPACE="models"
IMAGE_REPO="model-api"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/models"
CHARTS_DIR="$DIR/charts"

source "$BASE_DIR/scripts/common_functions.sh"

install() {
    local dir=$1
    local namespace=$2

    kubectl apply  -f "$CHARTS_DIR/service.yaml" \
    -f "$CHARTS_DIR/deployment.yaml" \
    -f "$CHARTS_DIR/ingress.yaml" \
    -n "$namespace"
}

start() {
    create_namespace "$NAMESPACE"
    # Build custom image and load it into the cluster
    build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER" 

    create_kubernetes_secret "env-secrets" "$NAMESPACE"  "--from-env-file=$DIR/.env"

    install "$DIR" "$NAMESPACE"
}

# Shutdown function
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