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

STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-minio.yaml"

source "$BASE_DIR/scripts/common_functions.sh"

start() {
    local app="minio"
    local env_file="$STORAGE_DIR/.env.$app"

    echo "Starting Minio..."
    #starting minio and creating initial buckets
    if docker compose --env-file "$env_file" -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Minio started"
        echo "Waiting for Minio initialization job to complete..."
        if ! docker wait storage-mc-datalake-init-job-1  &> /dev/null ; then
            echo "WARNING: Minio initialization job failed"
        else
            echo "Minio initialization job completed"

            # remove the completed job container
            docker rm storage-mc-datalake-init-job-1   &> /dev/null
        fi
    else
        echo "Failed to start Minio"
        exit 1
    fi 
}

shutdown() {
    local app="minio"
    local env_file="$STORAGE_DIR/.env.$app"

    shutdown_storage "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"
}

init(){
    create_env_file " $STORAGE_DIR/.env.minio"   "$STORAGE_DIR/.env-minio-template"
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