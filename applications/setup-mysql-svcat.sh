#!/bin/sh

set -x

# note it can take some time for plans to appear when running: `svcat get plans` after initial installation, let's check we have what we need first
until svcat get plans | grep cloud-sql-mysql; do sleep 5; echo 'Waiting for cloud-sql-mysql svcat plan to be available ...'; done

# follows steps here https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/tree/master/service-catalog/cloud-sql-mysql
# use env vars instead if set
PROJECT=${GCP_PROJECT:="spaterson-project"}
NAMESPACE=${GCP_NAMESPACE:="cloud-mysql"}
SVC_ACCT_NAME=${GCP_SVC_ACCT:="mysql-service-account-${RANDOM}"}
INSTANCE_NAME=${GCP_INST_NAME:="cloudsql-instance"}
INSTANCE_ID=${GCP_INST_ID:="gke-demo-mysql-${RANDOM}"}
CREDENTIALS_NAME=${GCP_CREDS_NAME:="cloudsql-credentials"}
# below are only used to create a sample manifest file
APP_IMAGE_NAME=${APP_IMAGE_NAME:="eu.gcr.io/spaterson-project/table-setting:latest"}
APP_NAME=${APP_NAME:="table-setting"}

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

# wait until the binding is ready
until svcat get binding --namespace cloud-mysql ${SVC_ACCT_NAME} | grep Ready; do sleep 5; echo 'Pending Service Account Binding Ready state...'; done

# since we're using RANDOM names, let's also create a cleanup script on the fly
SCRIPT_DIR=`dirname $0`
cat <<EOF > ${SCRIPT_DIR}/cleanup-mysql-svcat.sh
#!/bin/bash
gcloud iam service-accounts delete ${SVC_ACCT_NAME}@${PROJECT}.iam.gserviceaccount.com --quiet
kubectl delete namespace ${NAMESPACE}
#gcloud sql instances delete ${INSTANCE_ID} --quiet
EOF

# create the binding for the secret
cat <<EOF > ${SCRIPT_DIR}/cloudsql-binding.yaml
apiVersion: servicecatalog.k8s.io/v1beta1
kind: ServiceBinding
metadata:
  name: cloudsql-binding
  namespace: ${NAMESPACE}
spec:
  instanceRef:
    name: ${INSTANCE_NAME}
  secretName: ${CREDENTIALS_NAME}
  parameters:
    roles:
      - roles/cloudsql.client
    serviceAccount: ${SVC_ACCT_NAME}
EOF

# use the above manifest file to finish creating the deployment
kubectl create -f ${SCRIPT_DIR}/cloudsql-binding.yml
#wait until the binding is ready
until svcat get binding --namespace cloud-mysql cloudsql-binding | grep Ready; do sleep 5; echo 'Pending Cloud SQL Instance Binding Ready state...'; done
# the below is created for convenience, assuming that the Table Setting app is being used e.g.
# https://github.com/skpaterson/table-setting
# this is only created as a sample for convenience and not executed anywhere
cat <<EOF > ${SCRIPT_DIR}/sample-deployment.yml
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace:  ${NAMESPACE}
  labels:
    app: ${APP_NAME}
spec:
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
    spec:
      containers:
        - name: web
          image: ${APP_IMAGE_NAME}
          ports:
            - containerPort: 5000
          env:
            - name: DB_TYPE
              value: mysql
        - name: cloudsql-proxy
          image: gcr.io/cloudsql-docker/gce-proxy:1.11
          env:
            - name: CONNECTION_NAME
              valueFrom:
                secretKeyRef:
                  name: ${CREDENTIALS_NAME}
                  key: connectionName
          command: ["/cloud_sql_proxy",
                    "-instances=$(CONNECTION_NAME)=tcp:3306",
                    "-credential_file=/secrets/cloudsql/privateKeyData"]
          volumeMounts:
            - name: ${SVC_ACCT_NAME}
              mountPath: /secrets/cloudsql
              readOnly: true
      volumes:
        - name: ${SVC_ACCT_NAME}
          secret:
            secretName: ${SVC_ACCT_NAME}
        - name: cloudsql
          emptyDir:

---
apiVersion: v1
kind: Service
metadata:
  name: cloudsql-user-service
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
spec:
  selector:
    app: ${APP_NAME}
  ports:
  - port: 80
    targetPort: 5000
  type: LoadBalancer
EOF

