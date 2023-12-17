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

NAMESPACE="airflow"
AIRFLOW_VERSION="2.7.3"
IMAGE_REPO="custom-airflow"
IMAGE_TAG="latest"

DIR="$BASE_DIR/services/airflow"
CHARTS_DIR="$DIR/charts"

STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-airflow.yaml"


source "$BASE_DIR/scripts/common_functions.sh"

# Function to install or upgrade airflow
install_airflow() {
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

uninstall_airflow() {
    local namespace=$1

    if ! helm uninstall airflow --namespace "$namespace"; then
        echo "Failed to uninstall Airflow"
        exit 1
    fi
}

# Function to create secrets
create_secrets(){
    local namespace=$1

    source "$BASE_DIR/scripts/airflow_secrets.sh"

    create_webserver_secret "$namespace"
    fernet_key=$(create_or_update_fernet_key "$DIR/.env")
    create_fernet_secret "$namespace" "$fernet_key" 
    create_minio_connection_secret "$namespace" "$DIR/.env"
    create_lakehouse_secret "$namespace" "$DIR/.env"
    create_kaggle_connection_secret "$namespace" "$DIR/.env"
    create_postgres_metadata_db_secret "$namespace" "$DIR/.env"
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
    run_unit_tests

    create_namespace "$NAMESPACE"
    create_secrets "$NAMESPACE"

    if ! docker build -t "$IMAGE_REPO:$IMAGE_TAG" "$DIR"; then
        echo "Docker build failed"
        exit 1
    fi

    if ! kind load docker-image "$IMAGE_REPO:$IMAGE_TAG" --name "$CLUSTER"; then
        echo "Failed to load Docker image into Kind cluster"
        exit 1
    fi

    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Airflow Postgres with docker-compose"
        exit 1
    fi 

    if ! kubectl apply -f "$CHARTS_DIR/local-pv.yaml" || ! kubectl apply -f "$CHARTS_DIR/local-pvc.yaml"; then
        echo "Failed to apply Kubernetes PV/PVC configurations"
        exit 1
    fi   

    # Add and update helm repository
    install_airflow "$CHARTS_DIR" "$NAMESPACE"

    # Wait for container startup
    wait_for_container_startup "$NAMESPACE" airflow-web component=web

    if ! kubectl apply -f "$CHARTS_DIR/roles.yaml" || ! kubectl apply -f "$CHARTS_DIR/roles.yaml"; then
        echo "Failed to apply role configurations"
        exit 1
    fi
}

# shutdown function
shutdown() {
    kubectl delete namespace "$NAMESPACE"

    local app="airflow"
    local env_file="$STORAGE_DIR/.env.$app"

    # Check if .env file exists 
    shutdown_storage "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"
}

init(){
    # copy .env file if it doesn't exist
    # .env/.env.* are gitignored
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$CHARTS_DIR/.env.values.yaml"  "$CHARTS_DIR/values-template.yaml"
    create_env_file "$STORAGE_DIR/.env.airflow"  "$STORAGE_DIR/.env-airflow-template"
}

# Main execution
case $ACTION in 
    init|start|shutdown) 
        $ACTION ;;
    *) 
        echo "Error: Invalid action $ACTION"; 
        exit 1 
        ;;
esac