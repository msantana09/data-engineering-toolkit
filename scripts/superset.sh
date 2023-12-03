#!/bin/bash

# Setting default values 
ACTION="start"
CLUSTER="platform"
DELETE_DATA=false
BASE_DIR=".."

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
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
NAMESPACE="superset"
IMAGE_REPO="superset"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/superset"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-superset.yaml"

source "$BASE_DIR/scripts/common_functions.sh"

install() {
    local dir=$1
    local namespace=$2

    helm repo add superset https://apache.github.io/superset
    helm repo update
    if ! helm upgrade --install superset superset/superset\
        --namespace "$namespace" \
        --values "$dir/.env.values.yaml"; then
        echo "Failed to install/upgrade Superset"
        exit 1
    fi
}

start() {
    create_env_file "$DIR/.env.values.yaml"  "$DIR/values-template.yaml"
    create_env_file "$STORAGE_DIR/.env.superset"  "$STORAGE_DIR/.env-superset-template"
  
    create_namespace "$NAMESPACE"
    # Start Postgres Database
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Superset's Postgres Database with docker-compose"
        exit 1
    fi 
    install "$DIR" "$NAMESPACE"
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"

    local app="superset"
    local env_file="$STORAGE_DIR/.env.$app"
    
    shutdown_storage "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"

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