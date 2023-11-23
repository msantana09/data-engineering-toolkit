#!/bin/bash

# Setting default values
BASE_DIR=$1
CLUSTER="${2:-"platform"}"

source "$BASE_DIR/scripts/common_functions.sh"


# Function to check and create kind cluster

# Main execution
create_kind_cluster "$CLUSTER" "$BASE_DIR/infra/kind/kind-config.yaml"


# Apply ingress controller and wait for pods to be running
kubectl apply -f $BASE_DIR/infra/nginx/ingress-kind-nginx.yaml
wait_for_container_startup ingress-nginx ingress-nginx app.kubernetes.io/component=controller
