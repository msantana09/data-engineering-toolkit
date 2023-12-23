#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/_entry.sh" "$@"
source "$SCRIPT_DIR/common_functions.sh"

NAMESPACE="kubernetes-dashboard"
DIR="$BASE_DIR/services/$NAMESPACE"
CHARTS_DIR="$DIR/charts"


start() {    
    
    kubectl apply -f "$CHARTS_DIR/kubernetes-dashboard.yaml" \
    -f "$CHARTS_DIR/rbac.yaml"  

    helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
    helm repo update
    helm upgrade --install --set args={--kubelet-insecure-tls} metrics-server metrics-server/metrics-server --namespace kube-system
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