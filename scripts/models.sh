#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="models"
IMAGE_REPO="model-api"
IMAGE_TAG="latest"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$SERVICE_DIR/manifests"


start() {
    create_namespace "$SERVICE"

    create_kubernetes_secret "env-secrets" "$SERVICE"  "--from-env-file=$SERVICE_DIR/.env"

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$SERVICE_DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    kubectl apply  -f "$MANIFESTS_DIR/service.yaml" \
    -f "$MANIFESTS_DIR/ingress.yaml" \
    -n "$SERVICE"

    # run init job
    kubectl apply -f "$MANIFESTS_DIR/deployment-init.yaml" -n "$SERVICE"

    # run deployment-init.yaml and wait for it to complete before running main deployment
    if ! kubectl wait --for=condition=complete --timeout=600s job/model-api-init -n "$SERVICE" ; then
        echo "WARNING: Model API initialization job failed"
    else
        echo "Model API initialization job completed"

        # remove the completed job container
        kubectl delete job/model-api-init -n "$SERVICE"
        # run main deployment
        kubectl apply -f "$MANIFESTS_DIR/deployment.yaml" -n "$SERVICE"
    fi
}

# stop function
stop() {
   delete_namespace "$SERVICE"
}


init(){
    create_env_file "$SERVICE_DIR/.env"  "$SERVICE_DIR/.env-template"
    mkdir -p "$SERVICE_DIR/data"
}


# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"