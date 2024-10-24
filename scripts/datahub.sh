#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="datahub"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
CHARTS_DIR="$SERVICE_DIR/charts"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-$SERVICE.yaml"

dependencies=("kafka")



create_postgresql_secrets() {
    local env_file="$SERVICE_DIR/.env"
    local password=$(get_key_value "$env_file" POSTGRES_PASSWORD)

    create_kubernetes_secret "postgresql-secrets" "$SERVICE" "--from-literal=postgres-password=$password"
}

start() {

    for service in "${dependencies[@]}"; do
        script=("$BASE_DIR/scripts/$service.sh")
        run_script "$script" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
    done

    create_namespace "$SERVICE"
    create_postgresql_secrets 

    if ! docker compose --env-file "$STORAGE_DIR/.env.datahub"  \
        -f "$DOCKER_COMPOSE_FILE" up \
        -d datahub-postgres datahub-elasticsearch-01  &> /dev/null ; then
        echo "Failed to start Datahub's Postgres Database with docker-compose"
        exit 1
    fi 

    helm upgrade --install prerequisites datahub/datahub-prerequisites \
        --values "$CHARTS_DIR/prerequisites-values.yaml" --namespace $SERVICE

    # setting a 10 minute timeout for the datahub chart since it does a bunch of checks and upgrades at startup
    helm upgrade --install datahub datahub/datahub \
        --values "$CHARTS_DIR/values.yaml" --namespace $SERVICE --timeout 10m

}

# shutdown function
shutdown() {
    env_file="$STORAGE_DIR/.env.$SERVICE"

    delete_namespace "$SERVICE"

    shutdown_docker_compose_stack "$SERVICE" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"

    for service in "${dependencies[@]}"; do
        script=("$BASE_DIR/scripts/$service.sh")
        run_script "$script" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
    done
}

init(){
    # create .env file if it doesn't exist
    create_env_file "$SERVICE_DIR/.env"  "$SERVICE_DIR/.env-template"
    create_env_file "$STORAGE_DIR/.env.datahub"  "$STORAGE_DIR/.env-datahub-template"
}

# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"