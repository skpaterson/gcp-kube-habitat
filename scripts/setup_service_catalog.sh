#!/bin/bash

set -x

# this assumes setup_helm.sh has been run 
#assumes sc and svcat are installed

##helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
# see https://kubernetes.io/docs/tasks/service-catalog/install-service-catalog-using-helm/
helm repo update
helm search service-catalog
helm install svc-cat/catalog --name catalog --namespace catalog --set asyncBindingOperationsEnabled=true --set apiserver.storage.etcd.persistence.enabled=true --set calico_ipv4pool_ipip=off --wait
 #   -- wait \
 #   --set apiserver.storage.etcd.persistence.enabled=true
#https://cloud.google.com/kubernetes-engine/docs/how-to/add-on/service-catalog/install-service-catalog
##sc uninstall
##sc install
#sc remove-gcp-broker
#sc add-gcp-broker

# Note the above call fails with the following error (running interactively is fine)

#+ sc add-gcp-broker
#using project:  spaterson-project
#enabling a GCP API: servicebroker.googleapis.com
#enabling a GCP API: bigquery-json.googleapis.com
#enabling a GCP API: bigtableadmin.googleapis.com
#enabling a GCP API: ml.googleapis.com
#enabling a GCP API: pubsub.googleapis.com
#enabling a GCP API: spanner.googleapis.com
#enabling a GCP API: sqladmin.googleapis.com
#enabling a GCP API: storage-api.googleapis.com
#enabled required APIs:
#  servicebroker.googleapis.com
#  bigquery-json.googleapis.com
#  bigtableadmin.googleapis.com
#  ml.googleapis.com
#  pubsub.googleapis.com
#  spanner.googleapis.com
#  sqladmin.googleapis.com
#  storage-api.googleapis.com
#generated the key at:  /tmp/service-catalog-gcp843306878/key.json
#Broker "default", already exists
#Failed to configure the Service Broker
#Error: error deploying the Service Broker configs: deploy failed with output: exit status 1: error: unable to recognize "/tmp/service-catalog-gcp843306878/gcp-broker.yaml": no matches for servicecatalog.k8s.io/, Kind=ClusterServiceBroker


# Below will be run interactively:

#monitor broker for Fetched Catalog state
#until kubectl get clusterservicebrokers -o 'custom-columns=BROKER:.metadata.name,STATUS:.status.conditions[0].reason' | grep FetchedCatalog; do sleep 5; echo 'Waiting for Service Broker to be ready'; done
#svcat get plans
#until svcat get plans | grep NAME; do sleep 5; echo 'Waiting for GCP plans to be available ...'; done
# Grant the Owner role (roles/owner) to the cloudservices service account so that the service account can
# grant IAM permissions. Service Broker grants IAM permissions as part of binding to the service instances.
# see https://cloud.google.com/kubernetes-engine/docs/how-to/add-on/service-catalog/install-service-catalog#set_the_role_for_the_project_service_account
#GCP_PROJECT_ID=$(gcloud config get-value project)
#GCP_PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format='value(projectNumber)')
#gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
#    --member serviceAccount:${GCP_PROJECT_NUMBER}@cloudservices.gserviceaccount.com \
#    --role=roles/owner
