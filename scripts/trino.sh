#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

NAMESPACE="trino"
DIR="$BASE_DIR/services/trino"
CHARTS_DIR="$DIR/charts"

# Function to install or upgrade trino
install_trino() {
    local dir=$1
    local chartdir=$2
    local namespace=$3
    local lakehouse=$(<"$dir/catalogs/.env.lakehouse.properties")

    helm repo add trino https://trinodb.github.io/charts
    helm repo update

    if ! helm upgrade --install -f "$chartdir/trino.yaml" trino trino/trino \
        --set additionalCatalogs.lakehouse="$lakehouse" \
        --namespace "$namespace"  ; then
        echo "Failed to install/upgrade Trino"
        exit 1
    fi
    # Wait for container startup
    wait_for_container_startup "$NAMESPACE" trino component=coordinator

    # Create service to expose trino on port 8081 of host
    if ! kubectl apply -f  "$chartdir/service.yaml"  ; then
        echo "Failed to create Trino service"
        exit 1
    fi

}

start() {
    create_namespace "$NAMESPACE"
    install_trino "$DIR" "$CHARTS_DIR" "$NAMESPACE"
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"
}

init(){
    create_env_file "$DIR/catalogs/.env.lakehouse.properties"  "$DIR/catalogs/lakehouse.properties.template"

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