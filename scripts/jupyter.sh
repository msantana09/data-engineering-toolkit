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

NAMESPACE="jupyter"
IMAGE_REPO="custom-spark-jupyter"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/jupyter"
CHARTS_DIR="$DIR/charts"

source "$BASE_DIR/scripts/common_functions.sh"

start() {
   
    create_namespace "$NAMESPACE"
    create_kubernetes_secret "env-secrets" "$NAMESPACE"  "--from-env-file=$DIR/.env"

    # Build custom image and load it into the cluster
    build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER" 

    # Apply roles
    kubectl apply -f "$CHARTS_DIR/volumes.yaml" \
        -f "$CHARTS_DIR/deployment.yaml" \
        -f "$CHARTS_DIR/service.yaml" \
        -f "$CHARTS_DIR/roles.yaml" 
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