#!/bin/bash
echo "Create k8s cluster ..."
kind create cluster --config kind.yaml

echo "ECK ..."
kubectl apply -f eck/crds.yaml
kubectl wait -f eck/crds.yaml --for condition=Established
kubectl apply -f eck/operator.yaml
kubectl wait -n elastic-system pod/elastic-operator-0 \--for condition=Ready
kubectl apply -f eck/es-cluster.yaml
kubectl wait -n default elasticsearches/es-graylog --for=jsonpath='{.status.health}'=green --timeout=210s

echo "MongoDB ..."
kubectl apply -f mongodb-kubernetes-operator/crds.yaml
kubectl wait -f mongodb-kubernetes-operator/crds.yaml --for condition=Established
kubectl apply -f mongodb-kubernetes-operator/clusterwide
kubectl apply -k mongodb-kubernetes-operator/rbac --namespace default
kubectl create -f mongodb-kubernetes-operator/manager.yaml --namespace default
kubectl wait -n default deployment/mongodb-kubernetes-operator --for condition=Available=True --timeout=210s
kubectl apply -f mongodb-kubernetes-operator/mongodb-cluster.yaml --namespace default
kubectl wait -n default mongodbcommunity/mongodb-graylog --for=jsonpath='{.status.phase}'=Running --timeout=360s

echo "Graylog ..."
kubectl apply -f graylog
kubectl wait -n default deployment/graylog --for condition=Available=True --timeout=60s

echo
echo "Type 'kind delete cluster --name graylog-eck' to delete the k8s cluster."
