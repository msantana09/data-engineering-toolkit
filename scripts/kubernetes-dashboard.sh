#!/bin/bash
BASE_DIR=".."

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/_entry.sh" "$@"
source "$SCRIPT_DIR/common_functions.sh"

NAMESPACE="kubernetes-dashboard"
DIR="$BASE_DIR/services/$NAMESPACE"
MANIFESTS_DIR="$DIR/manifests"
CHARTS_DIR="$DIR/charts"


start() {    
    
    kubectl apply -f "$MANIFESTS_DIR/kubernetes-dashboard.yaml" \
    -f "$MANIFESTS_DIR/rbac.yaml"  

    helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
    helm repo update
    helm upgrade --install --set args={--kubelet-insecure-tls} metrics-server metrics-server/metrics-server --namespace kube-system

    # Running metric-server on Kind Kubernetes
    # https://gist.github.com/sanketsudake/a089e691286bf2189bfedf295222bd43
    kubectl patch deployment metrics-server -n kube-system --patch "$(cat "$CHARTS_DIR/metric-server-patch.yaml")"
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