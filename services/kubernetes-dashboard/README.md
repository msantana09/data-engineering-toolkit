# Accessing the Kubernetes Dashboard
## Generate Token
Copy the token returned by command
```
    kubectl -n kubernetes-dashboard create token admin-user
```

## Run proxy server to access k8s api
Execute in a separate terminal 
```
    kubectl proxy
```
## Access dashboard
Once the UI loads, paste the copied token to login
```
    # port might differ based on proxy command
    http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```