start_local_registry(){
    # 1. Create registry container unless it already exists
    reg_name='kind-registry'
    reg_port='5001'
    if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
    docker run \
        -d --restart=always -p "127.0.0.1:${reg_port}:5000" \
        --network bridge \
        --name "${reg_name}" \
        -v registry_data:/var/lib/registry \
        --memory="0.5g" \
        --cpus=".25" \
        registry:2
    fi
}

# stop local registry
stop_local_registry(){
    reg_name='kind-registry'
    reg_port='5001'

    # if it exists, stop and remove it
    if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" == 'true' ]; then
        docker stop "${reg_name}"
        docker rm "${reg_name}"
    fi
}



finish_local_registry_setup(){
    BASE_DIR=$1
    reg_port='5001'
    # 3. Add the registry config to the nodes
    #
    # This is necessary because localhost resolves to loopback addresses that are
    # network-namespace local.
    # In other words: localhost in the container is not localhost on the host.
    #
    # We want a consistent name that works from both ends, so we tell containerd to
    # alias localhost:${reg_port} to the registry container when pulling images
    REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
    for node in $(kind get nodes --name platform); do
    docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
    cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
    [host."http://${reg_name}:5000"]
EOF
    done

    # 4. Connect the registry to the cluster network if not already connected
    # This allows kind to bootstrap the network but ensures they're on the same network
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
    docker network connect "kind" "${reg_name}"
    fi

    # 5. Document the local registry
    # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    kubectl apply -f "$BASE_DIR/infra/kind/local-registry-config.yaml"
}
