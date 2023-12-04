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

NAMESPACE="datahub"
DIR="$BASE_DIR/services/datahub"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-datahub.yaml"

source "$BASE_DIR/scripts/common_functions.sh"

create_neo4j_secrets() {
    local namespace=$1
    local env_file=$2
    local password=$(get_key_value "$env_file" NEO4J_PASSWORD)
    local auth=$(get_key_value "$env_file" NEO4J_AUTH)

    create_kubernetes_secret "neo4j-secrets" "$namespace" "--from-literal=neo4j-password=$password --from-literal=NEO4J_AUTH=$auth"
}

create_postgresql_secrets() {
    local namespace=$1
    local env_file=$2
    local password=$(get_key_value "$env_file" POSTGRES_PASSWORD)

    create_kubernetes_secret "postgresql-secrets" "$namespace" "--from-literal=postgres-password=$password"
}

start() {
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$STORAGE_DIR/.env.datahub"  "$STORAGE_DIR/.env-datahub-template"


    create_namespace "$NAMESPACE"
    create_neo4j_secrets "$NAMESPACE" "$DIR/.env"
    create_postgresql_secrets "$NAMESPACE" "$DIR/.env"

    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Datahub's Postgres Database with docker-compose"
        exit 1
    fi 

    helm upgrade --install prerequisites datahub/datahub-prerequisites \
        --values "$DIR/prerequisites-values.yaml" --namespace $NAMESPACE

    helm upgrade --install datahub datahub/datahub \
        --values "$DIR/values.yaml" --namespace $NAMESPACE 

}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"

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