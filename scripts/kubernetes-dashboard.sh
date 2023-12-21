#!/bin/bash

# Setting default values 
if [[ $# -gt 0 ]]; then
    ACTION="$1"
    shift
fi
CLUSTER="platform"
DELETE_DATA=false
BASE_DIR=".."

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

NAMESPACE="kubernetes-dashboard"
DIR="$BASE_DIR/services/$NAMESPACE"
CHARTS_DIR="$DIR/charts"

source "$BASE_DIR/scripts/common_functions.sh"


start() {    
    kubectl apply -f "$CHARTS_DIR/kubernetes-dashboard.yaml" \
    -f "$CHARTS_DIR/rbac.yaml"  
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