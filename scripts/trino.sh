#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="trino"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
CHARTS_DIR="$SERVICE_DIR/charts"


start() {
    create_namespace "$SERVICE"
    local lakehouse_properties=$(<"$SERVICE_DIR/catalogs/.env.lakehouse.properties")

    helm repo add trino https://trinodb.github.io/charts
    helm repo update

    if ! helm upgrade --install -f "$CHARTS_DIR/trino.yaml" trino trino/trino \
        --set additionalCatalogs.lakehouse="$lakehouse_properties" \
        --namespace "$SERVICE"  ; then
        echo "Failed to install/upgrade Trino"
        exit 1
    fi
    # Wait for container startup
    wait_for_container_startup "$SERVICE" trino app.kubernetes.io/component=coordinator

    # Create service to expose trino on port 8081 of host
    if ! kubectl apply -f  "$CHARTS_DIR/service.yaml"  ; then
        echo "Failed to create Trino service"
        exit 1
    fi

}

# stop function
stop() {
    delete_namespace "$SERVICE"
}

init(){
    create_env_file "$SERVICE_DIR/catalogs/.env.lakehouse.properties"  "$SERVICE_DIR/catalogs/lakehouse.properties.template"
}


# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"