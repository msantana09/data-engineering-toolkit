#!/bin/bash

# Setting default values 
ACTION="${1:-start}"
BASE_DIR="${2:-../}"
CLUSTER="${3:-platform}"
NAMESPACE="${4:-airflow}"
AIRFLOW_VERSION="${5:-2.7.3}"
IMAGE_REPO="${6:-custom-airflow}"
IMAGE_TAG="${7:-latest}"



AIRFLOW_DIR="$BASE_DIR/services/airflow"

source "$BASE_DIR/scripts/common_functions.sh"

# Source environment variables
source "$AIRFLOW_DIR/.env"


# Function to install or upgrade airflow
install_airflow() {
    local dir=$1
    local namespace=$2

    helm upgrade --install airflow airflow-stable/airflow \
        --namespace "$namespace" \
        --version "8.X.X" \
        --values "$dir/airflow-helm.yaml"  
}

uninstall_airflow() {
    local dir=$1
    local namespace=$2

    helm uninstall airflow  \
        --namespace "$namespace" 
}

# Function to create secrets
create_secrets(){
    local namespace=$1


    # Create webserver secret
    local webserver_secret=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
    kubectl create secret generic airflow-webserver-secret --namespace "$namespace" \
        --from-literal="key=$webserver_secret" 

    # Create fernet secret
    env_fernet_key="AIRFLOW__CORE__FERNET_KEY"
    fernet_key=$(get_key_value "$AIRFLOW_DIR/.env" $env_fernet_key)

    if [ -z "$fernet_key" ]; then
        # Check if the cryptography package is installed
        if ! python -c "import cryptography" &> /dev/null; then
            echo "cryptography is not installed. Installing..."
            pip install cryptography
        fi

        # Generate a Fernet key
        fernet_key=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")

        echo "Adding fernet key to Airflow's .env file."
        update_or_add_key "$AIRFLOW_DIR/.env" "$env_fernet_key" "$fernet_key"
    else
        echo "Using the existing fernet key from Airflow's .env file."
    fi

    kubectl create secret generic airflow-fernet-secret --namespace "$namespace" \
        --from-literal="key=$fernet_key" 

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

    # Storing database credentials in a secret
    POSTGRES_USER=$(get_key_value "$AIRFLOW_DIR/.env" POSTGRES_USER)
    POSTGRES_PASSWORD=$(get_key_value "$AIRFLOW_DIR/.env" POSTGRES_PASSWORD)
    kubectl create secret generic postgres-metadata-db \
        --namespace "$namespace" \
        --from-literal="username=$POSTGRES_USER" \
        --from-literal="password=$POSTGRES_PASSWORD"            

}


start() {
    create_env_file "$AIRFLOW_DIR/.env"  "$AIRFLOW_DIR/.env.template"

    # Main execution
    create_namespace "$NAMESPACE"
    create_secrets "$NAMESPACE"
    build_and_load_image "$AIRFLOW_DIR" "$IMAGE_REPO" "$IMAGE_TAG" "$CLUSTER"

    docker compose -f "$BASE_DIR/services/storage/docker-compose.yaml" up -d airflow-postgres 

    kubectl apply -f "$AIRFLOW_DIR/local-pv.yaml"
    kubectl apply -f "$AIRFLOW_DIR/local-pvc.yaml"

    # Add and update helm repository
    helm repo add apache-airflow https://airflow.apache.org
    helm repo update
    install_airflow "$AIRFLOW_DIR"  "$NAMESPACE"

    # Wait for container startup
    wait_for_container_startup airflow airflow-web component=web

    # Apply custom ingress rules
    kubectl apply -f "$AIRFLOW_DIR/ingress.yaml"
}

# Destroy function
destroy() {
    kubectl delete namespace "$NAMESPACE"
}

# Main execution
case $ACTION in
    start|destroy)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac