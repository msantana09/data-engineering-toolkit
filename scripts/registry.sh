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
