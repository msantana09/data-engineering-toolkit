#!/bin/bash

# Setting default values 
if [[ $# -gt 0 ]]; then
    ACTION="$1"
    shift
fi
CLUSTER="platform"
DELETE_DATA=false
BASE_DIR=".."
SERVICE="kafka"
NAMESPACE="kafka"
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

DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$DIR/manifests"
CHARTS_DIR="$DIR/charts"

source "$BASE_DIR/scripts/common_functions.sh"

start() {
    echo "Starting $SERVICE..."
    
    # install kafka
    kubectl apply -f "$MANIFESTS_DIR/namespace.yaml" \
    -f "$MANIFESTS_DIR/zookeeper.yaml" \
    -f "$MANIFESTS_DIR/kafka.yaml" \
    -f "$MANIFESTS_DIR/schema-registry.yaml"
    
    # install kafka ui
    helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts
    helm install kafka-ui kafka-ui/kafka-ui  --namespace "$NAMESPACE" -f "$CHARTS_DIR/.env.ui.values.yaml"
}

shutdown() {
    kubectl delete namespace "$NAMESPACE"
}

init(){
    echo "Initializing $SERVICE..."
    create_env_file "$CHARTS_DIR/.env.ui.values.yaml"  "$CHARTS_DIR/ui-values-template.yaml"
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