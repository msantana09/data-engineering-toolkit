#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

SERVICE="airflow"
AIRFLOW_VERSION="2.10.2"
IMAGE_REPO="custom-airflow"
IMAGE_TAG="latest"
SERVICE_DIR="$BASE_DIR/services/$SERVICE"
MANIFESTS_DIR="$SERVICE_DIR/manifests"
CHARTS_DIR="$SERVICE_DIR/charts"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-$SERVICE.yaml"



# Function to install or upgrade airflow
install_airflow_helm_chart() {
    helm repo add airflow-stable https://airflow-helm.github.io/charts
    helm repo update
    if ! helm upgrade --install airflow airflow-stable/airflow \
        --namespace "$SERVICE" \
        --values "$CHARTS_DIR/.env.values.yaml"; then
        echo "Failed to install/upgrade Airflow"
        exit 1
    fi
}

# run unit tests
run_unit_tests() {
    echo "Running unit tests"
    python3  -m unittest  discover -s "$SERVICE_DIR/tests"
    # throw error if unit tests fail
    if [ $? -ne 0 ]; then
        echo "Unit tests failed"
        exit 1
    fi

    echo "Unit tests passed"
}


start() {
    
    if ! run_unit_tests ; then
        echo "Unit tests failed"
        exit 1
    fi

    create_namespace "$SERVICE"

    source "$BASE_DIR/scripts/helper_functions/airflow/secrets.sh"
    create_secrets "$SERVICE" "$SERVICE_DIR"

    if ! build_and_load_image "$SERVICE_DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi
    

    if ! docker compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Airflow Postgres with docker-compose"
        exit 1
    fi 

    if ! kubectl apply -f "$MANIFESTS_DIR/local-pv.yaml" || ! kubectl apply -f "$MANIFESTS_DIR/local-pvc.yaml"; then
        echo "Failed to apply Kubernetes PV/PVC configurations"
        exit 1
    fi   

    # Add and update helm repository (depends on pv/pvc)
    install_airflow_helm_chart 

    # Apply role configurations (Service Account created by Helm chart)
    if ! kubectl apply -f "$MANIFESTS_DIR/roles.yaml" ; then
        echo "Failed to apply role configurations"
        exit 1
    fi

    # Wait for container startup
    wait_for_container_startup "$SERVICE" airflow-web component=web
}

# shutdown function
shutdown() {
    local env_file="$STORAGE_DIR/.env.$SERVICE"

    # check if namespace exists, and if it does, delete it
    if kubectl get namespace "$SERVICE" &> /dev/null; then
        kubectl delete namespace "$SERVICE"
    fi

    # Check if .env file exists 
    shutdown_docker_compose_stack "$SERVICE" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"

    delete_pvs "app=airflow" 
}

init(){
    # copy .env file if it doesn't exist
    # .env/.env.* are gitignored
    create_env_file "$SERVICE_DIR/.env"  "$SERVICE_DIR/.env-template"
    create_env_file "$CHARTS_DIR/.env.values.yaml"  "$CHARTS_DIR/values-template.yaml"
    create_env_file "$STORAGE_DIR/.env.airflow"  "$STORAGE_DIR/.env-airflow-template"
}

# Main execution
source "$SCRIPT_DIR/helper_functions/action_execution.sh"