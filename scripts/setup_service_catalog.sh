#!/bin/sh

set -x

# this assumes setup_helm.sh has been run 
#assumes sc and svcat are installed

helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
# see https://kubernetes.io/docs/tasks/service-catalog/install-service-catalog-using-helm/
helm repo update
helm search service-catalog
helm install svc-cat/catalog --name catalog --namespace catalog --set asyncBindingOperationsEnabled=true --set apiserver.storage.etcd.persistence.enabled=true --wait
 #   -- wait \
 #   --set apiserver.storage.etcd.persistence.enabled=true
#https://cloud.google.com/kubernetes-engine/docs/how-to/add-on/service-catalog/install-service-catalog
sc add-gcp-broker
# note the above call can take time...
svcat get plans
until svcat get plans | grep NAME; do sleep 5; echo 'Waiting for GCP broker to be ready ...'; done

# Grant the Owner role (roles/owner) to the cloudservices service account so that the service account can
# grant IAM permissions. Service Broker grants IAM permissions as part of binding to the service instances.
# see https://cloud.google.com/kubernetes-engine/docs/how-to/add-on/service-catalog/install-service-catalog#set_the_role_for_the_project_service_account
GCP_PROJECT_ID=$(gcloud config get-value project)
GCP_PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
    --member serviceAccount:${GCP_PROJECT_NUMBER}@cloudservices.gserviceaccount.com \
    --role=roles/owner
