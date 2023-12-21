# Accessing the Kubernetes Dashboard
## Generate Token
```
    kubectl -n kubernetes-dashboard create token admin-user
```

## Run proxy server tp access k8s api
```
    kubectl proxy
```
## Access dashboard
```
    # port might differ based on proxy command
    http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```