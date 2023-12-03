#!/bin/bash

# Setting default values 

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

NAMESPACE="trino"

DIR="$BASE_DIR/services/trino"

source "$BASE_DIR/scripts/common_functions.sh"

# Function to install or upgrade trino
install_trino() {
    local dir=$1
    local namespace=$2
    local lakehouse=$(<"$dir/catalogs/.env.lakehouse.properties")

    helm repo add trino https://trinodb.github.io/charts
    helm repo update

    if ! helm upgrade --install -f "$dir/trino.yaml" trino trino/trino \
        --set additionalCatalogs.lakehouse="$lakehouse" \
        --namespace "$namespace"  ; then
        echo "Failed to install/upgrade Trino"
        exit 1
    fi

    # Create service to expose trino on port 8081 of host
    if ! kubectl apply -f  "$dir/service.yaml"  ; then
        echo "Failed to create Trino service"
        exit 1
    fi

}

start() {
    create_env_file "$DIR/catalogs/.env.lakehouse.properties"  "$DIR/catalogs/lakehouse.properties.template"
    create_namespace "$NAMESPACE"
    install_trino "$DIR" "$NAMESPACE"
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"
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