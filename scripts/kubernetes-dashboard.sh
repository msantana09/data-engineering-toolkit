#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="kubernetes-dashboard"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$SERVICE_DIR/manifests"
CHARTS_DIR="$SERVICE_DIR/charts"


start() {    
    
    kubectl apply -f "$MANIFESTS_DIR/kubernetes-dashboard.yaml" \
    -f "$MANIFESTS_DIR/rbac.yaml"  
}

# shutdown function
shutdown() {
    delete_namespace "$NAMESPACE"
}

init(){
    # nothing to do
    echo ""
}

# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"