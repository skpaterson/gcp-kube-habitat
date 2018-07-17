#!/bin/sh

set -x

# this assumes setup_helm.sh has been run and svcat is installed

helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
# see https://kubernetes.io/docs/tasks/service-catalog/install-service-catalog-using-helm/
helm repo update
helm search service-catalog
helm install svc-cat/catalog --name catalog --namespace catalog
 #   -- wait \
 #   --set apiserver.storage.etcd.persistence.enabled=true
svcat get plans
