#!/bin/bash

# Setting default values 
ACTION="${1:-start}"
BASE_DIR="${2:-../}"
CLUSTER="${3:-platform}"
NAMESPACE="${4:-airflow}"
AIRFLOW_VERSION="${5:-2.7.3}"
IMAGE_REPO="${6:-custom-airflow}"
IMAGE_TAG="${7:-latest}"

DIR="$BASE_DIR/services/airflow"

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
    create_minio_connection_secret "$namespace"
    create_lakehouse_secret "$namespace" "$DIR/.env"
    create_kaggle_connection_secret "$namespace"
    create_postgres_metadata_db_secret "$namespace" "$DIR/.env"
}


start() {
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$DIR/.env.values.yaml"  "$DIR/values-template.yaml"

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

    if ! docker-compose -f "$BASE_DIR/services/storage/docker-compose.yaml" up -d airflow-postgres; then
        echo "Failed to start Airflow Postgres with docker-compose"
        exit 1
    fi 

    if ! kubectl apply -f "$DIR/local-pv.yaml" || ! kubectl apply -f "$DIR/local-pvc.yaml"; then
        echo "Failed to apply Kubernetes PV/PVC configurations"
        exit 1
    fi   
    

    # Add and update helm repository
    install_airflow "$DIR"  "$NAMESPACE"

    # Wait for container startup
    wait_for_container_startup "$NAMESPACE" airflow-web component=web

}

# Destroy function
destroy() {
    if ! kubectl delete namespace "$NAMESPACE"; then
        echo "Failed to delete namespace $NAMESPACE"
        exit 1
    fi
}

# Main execution
case $ACTION in
    start|destroy) $ACTION ;;
    *) echo "Error: Invalid action $ACTION"; exit 1 ;;
esac