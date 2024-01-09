#!/bin/bash

# exit on error
set -e

# Setting default values 
if [[ $# -gt 0 ]]; then
    ACTION="$1"
    shift
fi
BASE_DIR=".."
CLUSTER="platform"
DELETE_DATA=false

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

