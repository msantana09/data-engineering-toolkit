#!/bin/bash
BASE_DIR=".."

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

NAMESPACE="kubernetes-dashboard"
DIR="$BASE_DIR/services/$NAMESPACE"
MANIFESTS_DIR="$DIR/manifests"
CHARTS_DIR="$DIR/charts"


start() {    
    
    kubectl apply -f "$MANIFESTS_DIR/kubernetes-dashboard.yaml" \
    -f "$MANIFESTS_DIR/rbac.yaml"  
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"
}

init(){
    # nothing to do
    echo ""
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