# Main execution
execute_action() {
    case $1 in
        init|start|stop)
            $1
            ;;
        *)
            echo "Error: Invalid action $1"
            exit 1
            ;;
    esac
}
ACTION=$1
execute_action "$ACTION"