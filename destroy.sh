CLUSTER="${1:-"platform"}"
NAMESPACE="${2:-"airflow"}"

kubectl delete namespace $NAMESPACE
kind delete clusters $CLUSTER