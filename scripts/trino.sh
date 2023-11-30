#!/bin/bash

# Setting default values 
ACTION="${1:-start}"
BASE_DIR="${2:-../}"
CLUSTER="${3:-platform}"
NAMESPACE="${4:-trino}"

DIR="$BASE_DIR/services/trino"

source "$BASE_DIR/scripts/common_functions.sh"

# Function to install or upgrade trino
install_trino() {
    local dir=$1
    local namespace=$2
    local lakehouse=$(<"$dir/catalogs/.env.lakehouse.properties")

    if ! helm upgrade --install -f "$dir/trino.yaml" trino trino/trino \
        --set additionalCatalogs.lakehouse="$lakehouse" \
        --namespace "$namespace"  ; then
        echo "Failed to install/upgrade Trino"
        exit 1
    fi
}

start() {
    create_env_file "$DIR/catalogs/.env.lakehouse.properties"  "$DIR/catalogs/lakehouse.properties.template"
    create_namespace "$NAMESPACE"
    helm repo add trino https://trinodb.github.io/charts
    helm repo update

    install_trino "$DIR" "$NAMESPACE"
}

# Destroy function
destroy() {
    kubectl delete namespace "$NAMESPACE"
}

# Main execution
case $ACTION in
    start|destroy)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac