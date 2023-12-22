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

NAMESPACE="datahub"
DIR="$BASE_DIR/services/datahub"
CHARTS_DIR="$DIR/charts"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-datahub.yaml"

source "$BASE_DIR/scripts/common_functions.sh"

create_postgresql_secrets() {
    local namespace=$1
    local env_file=$2
    local password=$(get_key_value "$env_file" POSTGRES_PASSWORD)

    create_kubernetes_secret "postgresql-secrets" "$namespace" "--from-literal=postgres-password=$password"
}

start() {
    create_namespace "$NAMESPACE"
    create_postgresql_secrets "$NAMESPACE" "$DIR/.env"

    if ! docker-compose --env-file "$STORAGE_DIR/.env.datahub"  -f "$DOCKER_COMPOSE_FILE" up -d datahub-postgres datahub-elasticsearch-01  &> /dev/null ; then
        echo "Failed to start Datahub's Postgres Database with docker-compose"
        exit 1
    fi 

    helm upgrade --install prerequisites datahub/datahub-prerequisites \
        --values "$CHARTS_DIR/prerequisites-values.yaml" --namespace $NAMESPACE

    # setting a 10 minute timeout for the datahub chart since it does a bunch of checks and upgrades at startup
    helm upgrade --install datahub datahub/datahub \
        --values "$CHARTS_DIR/values.yaml" --namespace $NAMESPACE --timeout 10m

}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"
    app="datahub"
    env_file="$STORAGE_DIR/.env.datahub"

    shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"
}

init(){
    # create .env file if it doesn't exist
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$STORAGE_DIR/.env.datahub"  "$STORAGE_DIR/.env-datahub-template"
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