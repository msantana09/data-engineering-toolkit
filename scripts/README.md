# Application Scripts
This directory contains scripts corresponding to the various applications deployed to the KinD cluster. They are meant to be executed by the [platform.sh](../platform.sh) script in the project's root directory.  

The [platform.sh](../platform.sh) script automatically scans this directory to identify valid applications based on script names. 

For example, if we wanted to add a new application like [Apache Nifi](https://nifi.apache.org/) to this project, you would:

1. Create a file named `nifi.sh`
2. Add the expected logic to `nifi.sh`, specifically:
    - Source the helper functions
    - Define the 3 core functions: start, stop, init
    - Source the execution function
    
    Here's an example:

    ```
    #!/bin/bash

    ####################################################
    # Source helper functions
    ## entry.sh - sets a few global variables, and validates input arguments
    ## common.sh - library of shared functions, extend as needed
    ####################################################
    SCRIPT_PATH="$(realpath "$0")"
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
    source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
    source "$SCRIPT_DIR/helper_functions/common.sh"


    # set any global variables used in the script 
    SERVICE="nifi"
    SERVICE_DIR="$BASE_DIR/services/$SERVICE"
    MANIFESTS_DIR="$SERVICE_DIR/manifests"
    CHARTS_DIR="$SERVICE_DIR/charts"


    ####################################################
    # Include the 3 core functions: start, stop, init
    ####################################################
    start() {
        echo "Starting $SERVICE..."
        
        # include deployment logic, such as installing a helm chart
    }

    stop() {
        # Include stop logic.  Normally this is simply deleting the namespace,
        # but could also include deleting persistent volumes, databases, etc...
        delete_namespace "$SERVICE" 
    }

    init(){
        # included your initialization logic, such as creating .env files or creating directories
        echo "Initializing $SERVICE"
    }


    ####################################################
    # Source the main execution script. 
    ####################################################
    # Main execution
    source "$SCRIPT_DIR/helper_functions/action_execution.sh"
    ```


