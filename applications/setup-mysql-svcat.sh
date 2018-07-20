#!/bin/sh

set -x

# follows steps here https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/tree/master/service-catalog/cloud-sql-mysql
# use env vars instead if set
PROJECT=${GCP_PROJECT:="spaterson-project"}
NAMESPACE=${GCP_NAMESPACE:="cloud-mysql"}
SVC_ACCT_NAME=${GCP_SVC_ACCT:="mysql-service-account-${RANDOM}"}
INSTANCE_NAME=${GCP_INST_NAME:="cloudsql-instance"}
INSTANCE_ID=${GCP_INST_ID:="gke-demo-mysql-${RANDOM}"}

kubectl create namespace ${NAMESPACE}
svcat provision ${INSTANCE_NAME} \
    --namespace ${NAMESPACE} \
    --class cloud-sql-mysql \
    --plan beta \
    --params-json '{
        "instanceId": "'${INSTANCE_ID}'",
        "databaseVersion": "MYSQL_5_7",
        "settings": {
            "tier": "db-n1-standard-1"
        }
    }'
svcat describe instance --namespace ${NAMESPACE} ${INSTANCE_NAME}
# create a service account to make the private key available in the cloud-mysql namespace as a secret
svcat provision ${SVC_ACCT_NAME} \
    --namespace ${NAMESPACE} \
    --class cloud-iam-service-account \
    --plan beta \
    --param accountId=${SVC_ACCT_NAME} \
    --param displayName="A service account for making private key available in ${NAMESPACE}"
# see https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/tree/master/service-catalog/cloud-sql

until svcat describe instance --namespace ${NAMESPACE} ${INSTANCE_NAME} | grep Status | grep Ready; do sleep 5; echo 'Pending MySQL DB Ready state...'; done
until svcat get instance --namespace ${NAMESPACE} ${SVC_ACCT_NAME} | grep Ready; do sleep 5; echo 'Pending MySQL Service Account Ready state...'; done

#create a binding to make the service account private key available in cloud-mysql
svcat bind --namespace ${NAMESPACE} ${SVC_ACCT_NAME}

# since we're using RANDOM names, let's also create a cleanup script on the fly
SCRIPT_DIR=`dirname $0`
cat <<EOF > ${SCRIPT_DIR}/cleanup-mysql-svcat.sh
#!/bin/bash
gcloud iam service-accounts delete ${SVC_ACCT_NAME}@${PROJECT}.iam.gserviceaccount.com --quiet
kubectl delete namespace ${NAMESPACE}
#gcloud sql instances delete ${INSTANCE_ID} --quiet
EOF