sleep 5;
until (/usr/bin/mc --quiet config host add minio http://minio-api-svc.minio.svc.cluster.local:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD) do echo '...waiting...' && sleep 1; done; 
/usr/bin/mc admin --quiet user add minio $MINIO_HIVE_USER $MINIO_HIVE_PASSWORD; 
/usr/bin/mc admin --quiet user add minio $MINIO_AIRFLOW_USER $MINIO_AIRFLOW_PASSWORD; 
/usr/bin/mc mb --quiet --ignore-existing minio/datalake; 
/usr/bin/mc mb --quiet --ignore-existing minio/platform; 
# readwrite users 
users=($MINIO_HIVE_USER $MINIO_AIRFLOW_USER) 
# Iterate over the users 
for user in "${users[@]}" 
do 
    # Get the current policy of the user \
    current_policy=$(mc admin user info minio $user | grep 'PolicyName' | cut -d: -f2 | tr -d ' ') \
    # Check if the current policy is 'readwrite' 
    if [ "$current_policy" != "readwrite" ] 
    then 
        # If not, attach the 'readwrite' policy 
        /usr/bin/mc admin --quiet policy attach minio readwrite --user $user 
    else 
        echo "Policy 'readwrite' is already attached to user '$user'" 
    fi 
done