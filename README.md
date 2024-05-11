# Graylog ECK demo on Kind

Graylog with _Elastic Cloud on Kubernetes_ demo using kind

## References

[Elastic Cloud on Kubernetes](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html)

[MongoDB Community Kubernetes Operator](https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/README.md)

[MongoDB Tools](https://www.mongodb.com/try/download/tools)

[Graylog](https://go2docs.graylog.org/5-2/downloading_and_installing_graylog/installing_graylog.html)

[Graylog Compatibility Matrix](https://go2docs.graylog.org/5-2/downloading_and_installing_graylog/installing_graylog.html?tocpath=Downloading%20and%20Installing%20Graylog%7CInstalling%20Graylog%7C_____0)


## Create the k8s cluster

```bash
$ kind create cluster --config kind.yaml
```

## Elasticsearch

```bash
$ kubectl apply -f eck/crds.yaml
$ kubectl wait \
    -f eck/crds.yaml \
    --for condition=Established
$ kubectl apply -f eck/operator.yaml
$ kubectl wait \
    -n elastic-system \
    pod/elastic-operator-0 \
    --for condition=Ready

$ kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

```bash
$ kubectl apply -f eck/es-cluster.yaml

$ kubectl wait -n default pod/es-graylog-es-master-0 --for condition=Ready
$ kubectl wait -n default pod/es-graylog-es-master-1 --for condition=Ready
$ kubectl wait -n default pod/es-graylog-es-master-2 --for condition=Ready

$ kubectl wait -n default elasticsearches/es-graylog --for=jsonpath='{.status.health}'=green
```

## Kibana ( optional )

```bash
$ kubectl apply -f eck/kibana.yaml
```

Access to the Kibana as `elastic` user:

```bash
$ kubectl get secret es-graylog-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
$ kubectl port-forward service/kibana-kb-http 5601
```

## MongoDB Kubernetes Operator

```bash
$ kubectl apply -f mongodb-kubernetes-operator/crds.yaml
$ kubectl wait \
    -f mongodb-kubernetes-operator/crds.yaml \
    --for condition=Established
$ kubectl apply -f mongodb-kubernetes-operator/clusterwide
$ kubectl apply -k mongodb-kubernetes-operator/rbac --namespace default
```

```bash
$ kubectl get role mongodb-kubernetes-operator --namespace default
$ kubectl get rolebinding mongodb-kubernetes-operator --namespace default
$ kubectl get serviceaccount mongodb-kubernetes-operator --namespace default
```

```bash
$ kubectl apply -f mongodb-kubernetes-operator/manager.yaml --namespace default

$ kubectl wait -n default deployment/mongodb-kubernetes-operator --for condition=Available=True
```

Deploy a Replica Set:

```bash
$ kubectl apply -f mongodb-kubernetes-operator/mongodb-cluster.yaml --namespace default

$ kubectl wait -n default mongodbcommunity/mongodb-graylog --for=jsonpath='{.status.phase}'=Running
```

Get MongoDB URI:

```bash
$ kubectl get secret mongodb-graylog-graylog-graylog -o jsonpath="{.data.connectionString\.standardSrv}" | base64 -d
```

Start a `mongosh` if necessary:

```bash
$ kubectl run mongosh --rm -it --image=rtsp/mongosh -- bash
```

## Graylog

```bash
$ kubectl apply -f graylog
$ kubectl wait -n default deployment/graylog --for condition=Available=True

$ kubectl port-forward service/graylog-svc 9000
```

## Cleanup

```bash
$ kind delete cluster --name graylog-eck
```

## Deploy using Task

[Task](https://taskfile.dev/)

>>> Task is a task runner / build tool that aims to be simpler and easier to use than, for example, GNU Make.

```bash
$ task graylog
```

