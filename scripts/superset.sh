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

NAMESPACE="superset"
IMAGE_REPO="superset"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/superset"
CHARTS_DIR="$DIR/charts"

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
    create_namespace "$NAMESPACE"
    # Start Postgres Database
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Superset's Postgres Database with docker-compose"
        exit 1
    fi 
    install "$CHARTS_DIR" "$NAMESPACE"
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"

    local app="superset"
    local env_file="$STORAGE_DIR/.env.$app"
    
    shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"

}

init(){
    create_env_file "$CHARTS_DIR/.env.values.yaml"  "$CHARTS_DIR/values-template.yaml"
    create_env_file "$STORAGE_DIR/.env.superset"  "$STORAGE_DIR/.env-superset-template"
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