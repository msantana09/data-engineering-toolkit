
# Function to delete a KinD cluster if it exists
delete_kind_cluster() {
    local cluster_name=$1

    # Check if the specified cluster exists
    if kind get clusters | grep -q "^$cluster_name$"; then
        echo "Cluster $cluster_name exists. Deleting..."
        kind delete cluster --name "$cluster_name"
        echo "Cluster $cluster_name deleted."
    else
        echo "Cluster $cluster_name does not exist. No action taken."
    fi
}

# Function to create a kind cluster
create_kind_cluster() {
    local cluster_name=$1
    local config_file=${2:-}

    # Check if kind command exists
    if ! command -v kind &> /dev/null; then
        echo "Error: kind command not found"
        return 1
    fi

    if ! kind get clusters | grep -q "^$cluster_name$"; then
        echo "Cluster $cluster_name does not exist. Creating..."
        if [[ -n $config_file ]]; then
            kind create cluster --name "$cluster_name" --config "$config_file"
        else
            kind create cluster --name "$cluster_name"
        fi
    else
        echo "Cluster $cluster_name already exists."
        local nodes_status=$(docker ps -q -f name="${cluster_name}-control-plane")
        if [[ -z $nodes_status ]]; then
            echo "Cluster $cluster_name exists but is not active. Proceeding to delete and recreate..."
            delete_kind_cluster "$cluster_name"
            create_kind_cluster "$cluster_name" "$config_file"
        else
            echo "Cluster $cluster_name is active."
        fi
    fi
}

# Function to check and create namespace
create_namespace() {
    local namespace=$1

    # Check if kubectl command exists
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl command not found"
        return 1
    fi

    if ! kubectl get namespace "$namespace" &> /dev/null; then
        echo "Namespace $namespace does not exist. Creating..."
        kubectl create namespace "$namespace"
    else
        echo "Namespace $namespace already exists."
    fi
}

# Function to build and load a docker image
build_and_load_image() {
    local build_path=$1
    local image_repo=$2
    local image_tag=$3

    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        echo "Error: docker command not found"
        return 1
    fi

    local_registry='localhost:5001'
    docker build  -t "$local_registry/$image_repo:$image_tag" "$build_path"

    # pushing to local registry
    docker push "$local_registry/$image_repo:$image_tag" 
}


# Function to wait for container startup
wait_for_container_startup() {
    local namespace=$1
    local pod_label=$2
    local selector=$3

    echo "Waiting for at least one container in the $pod_label pods to be ready..."

    while : ; do
        ready_pods=$(kubectl get pods -n "$namespace" \
            -l "$selector" \
            -o jsonpath='{.items[?(@.status.phase=="Running")].status.containerStatuses[?(@.ready==true)].name}' | wc -w)

        if [[ $ready_pods -gt 0 ]]; then
            echo "At least one container in the $pod_label pods is ready."
            break
        else
            echo "Waiting for containers to be ready..."
            sleep 5
        fi
    done
}


create_env_file(){
    local env_file=$1
    local template_file=$2

    # Check if .env file exists
    if [ ! -f  "$env_file" ]; then
        # If .env does not exist, copy .env-template to .env
        cp  "$template_file" "$env_file"
        echo "$env_file file created from $template_file."
    else
        echo "$env_file file already exists, using it."
    fi
}

# Function to update or add key
update_or_add_key() {
    local env_file=$1
    local key=$2
    local value=$3

    if grep -q "^$key=" "$env_file"; then
        # Key exists, check if the value is empty
        if grep -q "^$key=$" "$env_file"; then
            # Update the key with the new value
            # Use sed -i '' for macOS compatibility
            sed -i '' "s/^$key=$/$key=\"$value\"/" "$env_file" || sed -i "s/^$key=$/$key=\"$value\"/" "$env_file"
            echo "Updated $key with the provided value."  1>&2
        else
            # Key exists with a non-empty value, return the value
            local existing_value=$(grep "^$key=" "$env_file" | cut -d'=' -f2)
            echo "Key $key already exists"
        fi
    else
        # Key does not exist, add it
        echo "$key=$value" >> "$env_file"
        echo "Added $key to $env_file."
    fi
}

# Function to get the value of a key
get_key_value() {
    local env_file=$1
    local key=$2
    # Use grep to find the line and sed to extract the value
    grep "^$key=" "$env_file" | sed -E "s/^$key=\"?([^\"']*)\"?$/\1/"
}

check_requirements() {
    local requirements=("$@")
    for tool in "${requirements[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Error: '$tool' is not installed."
            exit 1
        fi
    done
}

# Function to make script executable if not already
run_script() {
    local script_path=$1

    if [[ ! -f "$script_path" ]]; then
        echo "Error: Script $script_path not found."
        exit 1
    fi

    if [[ ! -x "$script_path" ]]; then
        echo "Making script $script_path executable."
        chmod +x "$script_path"
    fi

    # Execute the script with the remaining arguments. If it fails, exit with the same status code
    if ! "$script_path" "${@:2}" ; then
        echo "$script_path failed to execute."
        exit 1
    fi
}

# Function to extract value from JSON
extract_json_value() {
    local json=$1
    local key=$2
    echo $json | grep -o "\"$key\": \"[^\"]*" | grep -o '[^"]*$'
}

create_kubernetes_secret() {
    local secret_name=$1
    local namespace=$2
    local secret_data=$3

    if ! kubectl get secret "$secret_name" --namespace "$namespace" &> /dev/null; then
        echo "Creating secret '$secret_name' in namespace '$namespace'."
        kubectl create secret generic "$secret_name" --namespace "$namespace" $secret_data
    else
        echo "Secret '$secret_name' already exists in namespace '$namespace'."
    fi
}

stop_docker_compose_stack() {
    local app=$1
    local env_file=$2
    local delete_data=$3
    local docker_compose_file=$4
    local env_option=""
    local action="Shutting down storage for"
    local volume_option=""

    if [[ -n $env_file ]]; then 
        if [[ ! -f $env_file ]]; then
            echo "Error: file not found - $env_file"
            exit 1
        fi
        env_option="--env-file $env_file"
    fi

    if [[ $delete_data == true ]]; then
        action="Deleting volumes for"
        volume_option="-v"
    fi

    echo "$action $app..."
    docker compose $env_option -f "$docker_compose_file" down $volume_option

}

stop_running_storage_containers(){
    local storage_dir=$1
    local delete_data=$2
    local apps=()

    # extract app labels from docker compose stack containers
    local storage_containers=$(docker ps -q --filter label=com.docker.compose.project=storage)
    for container_id in $storage_containers
    do
        local app="$(docker inspect $container_id --format '{{ index .Config.Labels "app"}}')"
        # add to apps array if not already present
        if [[ ! " ${apps[@]} " =~ " ${app} " ]]; then
            apps+=("$app")
        fi
    done

    for app in "${apps[@]}"
    do 
        echo "Shutting down storage services: $app"
        stop_docker_compose_stack "$app" "$storage_dir/.env.$app" "$delete_data" "$storage_dir/docker-compose-$app.yaml"
    done
}

delete_pvs() {
    local label=$1

    # Get all persistent volumes with label app=$app
    pvs=$(kubectl get pv -l "$label" -o jsonpath="{.items[*].metadata.name}")

    if [[ -n $pvs ]]; then
        echo "Deleting persistent volumes"
        echo "$pvs"

        # Iterate over the list of persistent volumes
        for pv in $pvs
        do
            # Delete each persistent volume
            kubectl delete pv $pv
        done
    else
        echo "No persistent volumes found with label $label"
    fi 
}

get_apps(){
    local directory=$1
    local apps=()

    # Iterate over the files in the specified directory
    while IFS= read -r file; do
        # Remove the directory path and file extension
        local file_name=$(basename "$file" | sed 's/\.[^.]*$//')
        # Add the file name to the array
        apps+=("$file_name")
    done < <(find "$directory" -maxdepth 1 -type f -name "*.sh")


    echo "${apps[@]}"
}

delete_namespace() {
    local namespace=$1

    # Check if kubectl command exists
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl command not found"
        return 1
    fi

    if kubectl get namespace "$namespace" &> /dev/null; then
        echo "Namespace $namespace exists. Deleting..."
        kubectl delete namespace "$namespace"
    else
        echo "Namespace $namespace does not exist. No action taken."
    fi
}