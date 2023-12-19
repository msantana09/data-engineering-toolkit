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

    if [[ -z $1 ]]; then
    # Skip empty arguments
        shift
        continue
    fi

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

DIR="$BASE_DIR/services/kafka"
DOCKER_COMPOSE_FILE="$DIR/kafka-full-stack.yaml"

source "$BASE_DIR/scripts/common_functions.sh"

start() {
    local app="kafka" 
    echo "Starting $app..."
    #starting minio and creating initial buckets
    if docker compose  -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "$app started" 
    else
        echo "Failed to start $app"
        exit 1
    fi 
}

shutdown() {
    local app="kafka" 
    local env_file=""

    echo  "$DOCKER_COMPOSE_FILE"

    shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"
}

init(){
    create_env_file "$DIR/.env.conduktor"  "$DIR/.env-conduktor-template"
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