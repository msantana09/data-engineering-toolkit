#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

NAMESPACE="airflow"
AIRFLOW_VERSION="2.7.3"
IMAGE_REPO="custom-airflow"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/airflow"
MANIFESTS_DIR="$DIR/manifests"
CHARTS_DIR="$DIR/charts"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-airflow.yaml"



# Function to install or upgrade airflow
install_airflow_helm_chart() {
    local dir=$1
    local namespace=$2

    helm repo add airflow-stable https://airflow-helm.github.io/charts
    helm repo update
    if ! helm upgrade --install airflow airflow-stable/airflow \
        --namespace "$namespace" \
        --values "$dir/.env.values.yaml"; then
        echo "Failed to install/upgrade Airflow"
        exit 1
    fi
}

# run unit tests
run_unit_tests() {
    echo "Running unit tests"
    python3  -m unittest  discover -s "$DIR/tests"
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

    create_namespace "$NAMESPACE"

    source "$BASE_DIR/scripts/airflow_secrets.sh"
    create_secrets "$NAMESPACE" "$DIR"

    if ! build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi
    

    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Airflow Postgres with docker-compose"
        exit 1
    fi 

    if ! kubectl apply -f "$MANIFESTS_DIR/local-pv.yaml" || ! kubectl apply -f "$MANIFESTS_DIR/local-pvc.yaml"; then
        echo "Failed to apply Kubernetes PV/PVC configurations"
        exit 1
    fi   

    # Add and update helm repository (depends on pv/pvc)
    install_airflow_helm_chart "$CHARTS_DIR" "$NAMESPACE"

    # Apply role configurations (Service Account created by Helm chart)
    if ! kubectl apply -f "$MANIFESTS_DIR/roles.yaml" ; then
        echo "Failed to apply role configurations"
        exit 1
    fi

    # Wait for container startup
    wait_for_container_startup "$NAMESPACE" airflow-web component=web
}

# shutdown function
shutdown() {
    local app="airflow"
    local env_file="$STORAGE_DIR/.env.$app"


    # check if namespace exists, and if it does, delete it
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        kubectl delete namespace "$NAMESPACE"
    fi

    # Check if .env file exists 
    shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"

    # Delete persistent volumes
    # Get all persistent volumes with label app=airflow
    pvs=$(kubectl get pv -l app=airflow -o jsonpath="{.items[*].metadata.name}")

    echo "Deleting persistent volumes"
    echo "$pvs"

    # Iterate over the list of persistent volumes
    for pv in $pvs
    do
        # Delete each persistent volume
        kubectl delete pv $pv
    done
}

init(){
    # copy .env file if it doesn't exist
    # .env/.env.* are gitignored
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$CHARTS_DIR/.env.values.yaml"  "$CHARTS_DIR/values-template.yaml"
    create_env_file "$STORAGE_DIR/.env.airflow"  "$STORAGE_DIR/.env-airflow-template"
}

case $ACTION in 
    init|start|shutdown) 
        $ACTION ;;
    *) 
        echo "Error: Invalid action $ACTION"; 
        exit 1 
        ;;
esac