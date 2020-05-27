#!/bin/bash
input() {
read -p "please input nfs server ip:" NFS_SERVER_IP 
read -p "please input nfs server path:" NFS_SERVER_PATH
read -p "please input storageclass name:" NFS_STORAGE_CLASS

cp -f deployment_templ.yaml  deployment.yaml
cp -f rbac_templ.yaml rbac.yaml
cp -f storageclass_templ.yaml storageclass.yaml
sed -i "s@NFS_SERVER_IP@${NFS_SERVER_IP}@g" deployment.yaml
sed -i "s@NFS_SERVER_PATH@${NFS_SERVER_PATH}@g" deployment.yaml
sed -i "s@NFS_STORAGE_CLASS@${NFS_STORAGE_CLASS}@g" deployment.yaml
sed -i "s@NFS_STORAGE_CLASS@${NFS_STORAGE_CLASS}@g" storageclass.yaml
}

nfs_client_provisioner(){
NAMESPACE=default
sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" rbac.yaml deployment.yaml
kubectl apply  -f rbac.yaml
kubectl apply  -f deployment.yaml
kubectl apply  -f storageclass.yaml
}


#pvc_check(){
#sleep 3
#echo -----------------------------------------
#kubectl get pvc -n monitoring
#}


input
nfs_client_provisioner
#pvc_check
