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
    local cluster_name=$4

    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        echo "Error: docker command not found"
        return 1
    fi

    docker build --pull -t "$image_repo:$image_tag" "$build_path"
    kind load docker-image "$image_repo:$image_tag" --name "$cluster_name"
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
            sleep 10
        fi
    done
}