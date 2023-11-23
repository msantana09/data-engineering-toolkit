#!/bin/bash

# Setting default values 
BASE_DIR="${1:-../}"
CLUSTER="${2:-platform}"
NAMESPACE="${3:-airflow}"
AIRFLOW_VERSION="${4:-2.7.3}"
IMAGE_REPO="${5:-custom-airflow}"
IMAGE_TAG="${6:-latest}"

AIRFLOW_DIR="$BASE_DIR/services/airflow"

# Source common functions and environment variables
source "$BASE_DIR/scripts/common_functions.sh"
source "$AIRFLOW_DIR/.env"


# Function to install or upgrade airflow
install_or_upgrade_helm_airflow() {
    local dir=$1
    local namespace=$2

    helm upgrade --install airflow airflow-stable/airflow \
        --namespace "$namespace" \
        --version "8.X.X" \
        --values "$dir/airflow-helm.yaml"  
}

# Function to create secrets
create_secrets(){
    local namespace=$1

    # Create webserver secret
    local webserver_secret=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
    kubectl create secret generic airflow-webserver-secret --namespace "$namespace" \
        --from-literal="key=$webserver_secret" 

    # Create fernet secret
    # Generate a 32-byte random string and base64 encode it
    local fernet_secret=$(head -c 32 /dev/urandom | base64)

    # Make the base64 string URL-safe
    # - Replace '+' with '-'
    # - Replace '/' with '_'
    # - Remove newline characters
    url_safe_fernet_secret=$(echo "$fernet_secret" | tr '+/' '-_' | tr -d '\n')
    echo "The generated fernet secret is $url_safe_fernet_secret"
    kubectl create secret generic airflow-fernet-secret --namespace "$namespace" \
        --from-literal="key=$url_safe_fernet_secret" 

    # Function to extract value from JSON
    extract_json_value() {
        local json=$1
        local key=$2
        echo $json | grep -o "\"$key\": \"[^\"]*" | grep -o '[^"]*$'
    }

    # Create Minio connection secret
    local minio_conn_json="${AIRFLOW_CONN_MINIO_DEFAULT//\'/}"
    local minio_login=$(extract_json_value "$minio_conn_json" "login")
    local minio_password=$(extract_json_value "$minio_conn_json" "password")
    local minio_endpoint_url=$(extract_json_value "$minio_conn_json" "endpoint_url")
    kubectl create secret generic minio-connection \
        --namespace "$namespace" \
        --from-literal="login=$minio_login" \
        --from-literal="password=$minio_password" \
        --from-literal="endpoint_url=$minio_endpoint_url" 
         

    # Create Kaggle connection secret
    local kaggle_conn_json="${AIRFLOW_CONN_KAGGLE_DEFAULT//\'/}"
    local kaggle_username=$(extract_json_value "$kaggle_conn_json" "username")
    local kaggle_key=$(extract_json_value "$kaggle_conn_json" "key")
    kubectl create secret generic kaggle-connection \
        --namespace "$namespace" \
        --from-literal="username=$kaggle_username" \
        --from-literal="key=$kaggle_key"
        
}

# Main execution
create_namespace "$NAMESPACE"
create_secrets "$NAMESPACE"
build_and_load_image "$AIRFLOW_DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER"

# Add and update helm repository
helm repo add apache-airflow https://airflow.apache.org
helm repo update
install_or_upgrade_helm_airflow "$AIRFLOW_DIR"  "$NAMESPACE"

# Wait for container startup
wait_for_container_startup airflow airflow-web component=web

# Apply custom ingress rules
kubectl apply -f "$AIRFLOW_DIR/ingress.yaml"