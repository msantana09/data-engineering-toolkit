#!/bin/bash

# Determine the base directory of the script
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_BASE_DIR="$(dirname "$SCRIPT_PATH")"
source $SCRIPT_BASE_DIR/common_functions.sh


create_webserver_secret() {
    local namespace=$1
    local webserver_secret=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)
    create_kubernetes_secret "airflow-webserver-secret" "$namespace" "--from-literal=key=$webserver_secret"
}


create_or_update_fernet_key() {
    local env_file=$1
    local env_fernet_key="AIRFLOW__CORE__FERNET_KEY"
    local fernet_key

    fernet_key=$(get_key_value "$env_file" $env_fernet_key)

    if [ -z "$fernet_key" ]; then
        if ! command -v python &> /dev/null || ! python -c "import cryptography" &> /dev/null; then
            echo "Python or cryptography is not installed. Installing cryptography..."  1>&2
            pip install cryptography || { echo "Failed to install cryptography"; exit 1; }
        fi

        fernet_key=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
        echo "Adding fernet key to Airflow's .env file."  1>&2
        update_or_add_key "$env_file" "$env_fernet_key" "$fernet_key"
    else
        echo "Using the existing fernet key from Airflow's .env file."  1>&2
    fi

    echo $fernet_key
}

create_fernet_secret() {
    local namespace=$1
    local fernet_key=$2
    create_kubernetes_secret "airflow-fernet-secret" "$namespace" "--from-literal=key=$fernet_key"
}

create_minio_connection_secret() {
    local namespace=$1
    local minio_conn_json="${AIRFLOW_CONN_MINIO_DEFAULT//\'/}"
    local minio_login=$(extract_json_value "$minio_conn_json" "login")
    local minio_password=$(extract_json_value "$minio_conn_json" "password")
    local minio_endpoint_url=$(extract_json_value "$minio_conn_json" "endpoint_url")
    
    create_kubernetes_secret "minio-connection" "$namespace" \
        "--from-literal=login=$minio_login \
         --from-literal=password=$minio_password \
         --from-literal=endpoint_url=$minio_endpoint_url"
}

create_lakehouse_secret() {
    local namespace=$1
    local env_file=$2

    local HIVE_ENDPOINT_URL=$(get_key_value "$env_file" HIVE_ENDPOINT_URL)
    local AWS_S3_LAKEHOUSE=$(get_key_value "$env_file" AWS_S3_LAKEHOUSE)
    local AWS_REGION=$(get_key_value "$env_file" AWS_REGION)
    local AWS_ACCESS_KEY_ID=$(get_key_value "$env_file" AWS_ACCESS_KEY_ID)
    local AWS_SECRET_ACCESS_KEY=$(get_key_value "$env_file" AWS_SECRET_ACCESS_KEY)
    local AWS_ENDPOINT_URL_S3=$(get_key_value "$env_file" AWS_ENDPOINT_URL_S3)

    create_kubernetes_secret "lakehouse-secret"  "$namespace" \
        "--from-literal=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
        --from-literal=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
        --from-literal=AWS_ENDPOINT_URL_S3=$AWS_ENDPOINT_URL_S3 \
        --from-literal=AWS_REGION=$AWS_REGION \
        --from-literal=HIVE_ENDPOINT_URL=$HIVE_ENDPOINT_URL \
        --from-literal=AWS_S3_LAKEHOUSE=$AWS_S3_LAKEHOUSE"
}

create_kaggle_connection_secret() {
    local namespace=$1
    local kaggle_conn_json="${AIRFLOW_CONN_KAGGLE_DEFAULT//\'/}"
    
    local kaggle_username=$(extract_json_value "$kaggle_conn_json" "username")
    local kaggle_key=$(extract_json_value "$kaggle_conn_json" "key")

    create_kubernetes_secret "kaggle-connection" "$namespace" \
        "--from-literal=username=$kaggle_username \
        --from-literal=key=$kaggle_key"
}

create_postgres_metadata_db_secret() {
    local namespace=$1
    local env_file=$2

    POSTGRES_USER=$(get_key_value "$env_file" POSTGRES_USER)
    POSTGRES_PASSWORD=$(get_key_value "$env_file" POSTGRES_PASSWORD)
    create_kubernetes_secret "postgres-metadata-db"  "$namespace" \
        "--from-literal=username=$POSTGRES_USER \
        --from-literal=password=$POSTGRES_PASSWORD"
}

