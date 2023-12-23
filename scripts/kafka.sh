#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"


SERVICE="kafka"
NAMESPACE="kafka" 
DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$DIR/manifests"
CHARTS_DIR="$DIR/charts"

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