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
    if [[ -z $1 ]]; then
    # Skip empty arguments
        shift
        continue
    fi
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

APP="minio"
DIR="$BASE_DIR/services/$APP"
CHARTS_DIR="$DIR/charts"
NAMESPACE="minio"
IMAGE_REPO_MC="custom-minio-mc"
IMAGE_TAG_MC="latest"

source "$BASE_DIR/scripts/common_functions.sh"

start() {
    local app="minio"
    local env_file="$DIR/.env.$app"

    kubectl apply -f "$CHARTS_DIR/namespace.yaml" 
    create_kubernetes_secret "env-secrets" "$NAMESPACE"  "--from-env-file=$DIR/.env"

    # Build custom Minio client image and load it into the cluster
    if ! build_and_load_image "$DIR" "$IMAGE_REPO_MC" "$IMAGE_TAG_MC" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi 

    # Apply charts
    kubectl apply -f "$CHARTS_DIR/minio-server.yaml" 
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