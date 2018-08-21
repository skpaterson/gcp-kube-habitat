# Habitat and Kubernetes on GCP (Google Cloud Platform)

This project is geared towards getting started quickly with Kubernetes and Habitat on GCP and follows 
similar steps to this [AKS and ACR Walkthrough](https://www.habitat.sh/blog/2018/05/aks-and-acr-walkthrough/).  In a GCP project, this:
- Creates a GKE container cluster
- Optionally creates a service account with privileges to push and pull images to the [Container Registry](https://cloud.google.com/container-registry/docs/)
- Uses [InSpec GCP](https://github.com/inspec/inspec-gcp) to test that the resources were created as expected, see [controls](controls)
- Configures kubectl command line tool
- Installs [Habitat Operator](https://github.com/habitat-sh/habitat-operator) to the Kubernetes cluster 
- Provides examples to quickly do something real in the cluster

## Prerequisites

Assuming a local development environment with Ruby installed:

1. *Install and configure the Google cloud SDK*

Download the [SDK](https://cloud.google.com/sdk/docs/) and run the installation:
```bash
./google-cloud-sdk/install.sh
```
2. Create credentials file via:
```bash
$ gcloud auth application-default login
```
If successful, this should be similar to:
```bash
$ cat ~/.config/gcloud/application_default_credentials.json 
{
  "client_id": "764086051850-6qr4p6gpi6hn50asdr.apps.googleusercontent.com",
  "client_secret": "d-fasdfasdfasdfaweroi23jknrmfs;f8sh",
  "refresh_token": "1/asdfjlklwna;ldkna'dfmk-lCkju3-yQmjr20xVZonrfkE48L",
  "type": "authorized_user"
}
```
3. Enable the appropriate APIs that you want to use:

- [Enable Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com/)
- [Enable Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com)

4. Install the Kubernetes CLI:
```bash
$ gcloud components install kubectl
``` 

5. Clone this repository and ensure all dependencies are installed.  For example, using bundler:

```bash
$ git clone https://github.com/skpaterson/gcp-kube-habitat
$ cd gcp-kube-habitat
$ gem install bundler
$ bundle install
```

6. Install habitat, see instructions [here](https://github.com/habitat-sh/habitat#install)

7. Install Terraform, see instructions [here](https://www.terraform.io/intro/getting-started/install.html)

8. Install Service Catalog, see instructions [here](https://cloud.google.com/kubernetes-engine/docs/how-to/add-on/service-catalog/install-service-catalog).  Confirm this is working via:

```bash
$ sc check
account: spaterson@chef.io
project: spaterson-project
zone:
Dependency check passed. You are good to go.
```

9. Install the Service Catalog CLI, see: [here](https://github.com/kubernetes-incubator/service-catalog/blob/master/docs/install.md#installing-the-service-catalog-cli)

10. Install Helm - see instructions [here](https://github.com/helm/helm/blob/master/docs/install.md)

## Create the resources

First, let's export an environment variable pointing at a GCP project ID of your choosing:
```bash
$ export GCP_PROJECT_ID=your-project-id
```
This is the only mandatory setting.  If preferred, another approach would be to edit `test/integration/configuration/gcp_config.rb` accordingly.

Optionally choose the primary and two additional zones where the Kubernetes cluster will run.  Not setting anything will result in the default values shown below:
```bash
$ export GCP_KUBE_CLUSTER_ZONE="europe-west1-d"
$ export GCP_KUBE_CLUSTER_ZONE_EXTRA1="europe-west1-b"
$ export GCP_KUBE_CLUSTER_ZONE_EXTRA2="europe-west1-c"
```
Choose a zone where there are enough IP addresses available (9 are required and some zones default to 8).  Navigate to  IAM and admin->Quotas and look for “Compute Engine API In-use IP addresses” to update this for a zone.

Optionally enable creating a service account for working with the container registry that could be used by Habitat Builders.  This is not created by default:
```
$ export CREATE_HABITAT_SERVICE_ACCOUNT=1
```

Initialize the terraform workspace:
```
$ bundle exec rake test:init_workspace
```

Create the terraform plan to stand up the Kubernetes cluster and service account:
```
$ bundle exec rake test:plan_integration_tests
```

Create the resources in GCP:
```
$ bundle exec rake test:setup_integration_tests
```

## Test the resources

Use InSpec GCP to test the resources that we just created:

```
$ bundle exec rake test:run_integration_tests
```

This can also be run directly with InSpec from the root directory of the repository via:

```
$ bundle exec inspec exec . -t gcp:// --attrs=test/integration/build/gcp-kube-attributes.yaml
```

Sample test output:

```
Profile: InSpec GCP Kube Habitat Tests (gcp-kube-habitat-tests)
Version: 0.1.0
Target:  gcp://764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com

  ✔  gcp-single-zone-1.0: Ensure single zone has the correct properties.
     ✔  Zone europe-west2-a should be up
     ✔  Zone europe-west2-b should be up
     ✔  Zone europe-west2-c should be up
  ✔  gcp-gke-container-cluster-1.0: Ensure the GKE Container Cluster was built correctly
     ✔  Cluster gcp-kube-cluster should exist
     ✔  Cluster gcp-kube-cluster name should eq "gcp-kube-cluster"
     ✔  Cluster gcp-kube-cluster zone should match "europe-west2-a"
     ✔  Cluster gcp-kube-cluster tainted? should equal false
     ✔  Cluster gcp-kube-cluster untrusted? should equal false
     ✔  Cluster gcp-kube-cluster status should eq "RUNNING"
     ✔  Cluster gcp-kube-cluster locations.sort should cmp == ["europe-west2-a", "europe-west2-b", "europe-west2-c"]
     ✔  Cluster gcp-kube-cluster master_auth.username should eq "gcp-kube-admin"
     ✔  Cluster gcp-kube-cluster master_auth.password should eq "%gwpasddssfl;kjdsfjklsdP!ah"
     ✔  Cluster gcp-kube-cluster network should eq "default"
     ✔  Cluster gcp-kube-cluster subnetwork should eq "default"
     ✔  Cluster gcp-kube-cluster node_config.disk_size_gb should eq 100
     ✔  Cluster gcp-kube-cluster node_config.image_type should eq "COS"
     ✔  Cluster gcp-kube-cluster node_config.machine_type should eq "n1-standard-1"
     ✔  Cluster gcp-kube-cluster node_ipv4_cidr_size should eq 24
     ✔  Cluster gcp-kube-cluster node_pools.count should eq 1
  ✔  gcp-generic-iam-service-account: Ensure that the Service Account is correctly set up
     ✔  IAM Service Account hab-svc-acct-whdeqkbduwvvbll display_name should eq "hab-svc-acct-whdeqkbduwvvbll"
     ✔  IAM Service Account hab-svc-acct-whdeqkbduwvvbll project_id should eq "spaterson-project"
     ✔  IAM Service Account hab-svc-acct-whdeqkbduwvvbll email should eq "hab-svc-acct-whdeqkbduwvvbll@spaterson-project.iam.gserviceaccount.com"


Profile: Google Cloud Platform Resource Pack (inspec-gcp)
Version: 0.4.0
Target:  gcp://764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com

     No tests executed.

Profile Summary: 3 successful controls, 0 control failures, 0 controls skipped
Test Summary: 22 successful, 0 failures, 0 skipped
```

## Set up the Kubernetes Cluster

The following command configures kubectl and installs the Habitat Operator in the Kubernetes cluster.
```
$ bundle exec rake test:setup_cluster
```
Note this operation is not idempotent!

Check things are working as expected via:
```
$ kubectl cluster-info
$ kubectl get pods
```

## Example 1 - run an application directly using Kubernetes

This is based on the Kubernetes example [here](https://kubernetes.io/docs/tasks/run-application/)

```
$ kubectl apply -f applications/nginx-deployment.yml
$ kubectl describe deployment nginx-deployment
$ kubectl get pods
$ kubectl expose deployment nginx-deployment --type=LoadBalancer --name=nginx-service
$ kubectl describe services nginx-service 
```
Using the public IP address from the last command, hit the URL and the trusty nginx startup page should be there. 

## Example 2 - run a simple Habitat example application

This example is based on [this article](https://kinvolk.io/blog/2017/12/get-started-with-habitat-on-kubernetes/). 

```
$ kubectl create -f applications/demo-application.yml
```

Check the status with `kubectl get pods` and wait for all pods to enter a running state.  

```
$ kubectl get pods
NAME                                    READY     STATUS              RESTARTS   AGE
habitat-demo-counter-68f6cb4448-srk2c   0/1       ContainerCreating   0          15s
habitat-operator-854d7dc494-j58kb       1/1       Running             0          5m
```

Navigate to the public IP address "External IP" listed by the following command at port `8000` and you will hopefully see a nice result.

```
$ kubectl get services front
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)          AGE
front     LoadBalancer   10.20.300.40   12.345.678.123   8000:32259/TCP   1m
```

## Example 3 - run a more realistic application (advanced)

Here we will deploy a separate application [Table Setting](https://github.com/skpaterson/table-setting) using a Cloud SQL database based on the [Kubernetes samples](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/blob/master/service-catalog/cloud-sql-mysql/README.md). 

First some preparatory work is required.  Assuming that the `setup_cluster` phase above was successful, we already have a GCP Service Broker in place.  This can be confirmed with the below command:

```
$ svcat get plans
  NAME             CLASS                      DESCRIPTION
+------+---------------------------+--------------------------------+
  beta   cloud-spanner               Cloud Spanner plan for the
                                     Beta release of the Google
                                     Cloud Platform Service Broker
  beta   cloud-iam-service-account   A Google Cloud Platform IAM
                                     service account
  beta   cloud-pubsub                Pub/Sub plan for the Beta
                                     release of the Google Cloud
                                     Platform Service Broker
  beta   cloud-sql-mysql             Cloud SQL - MySQL plan for
                                     the Beta release of the Google
                                     Cloud Platform Service Broker
  beta   bigquery                    BigQuery plan for the Beta
                                     release of the Google Cloud
                                     Platform Service Broker
  beta   cloud-bigtable              Bigtable plan for the Beta
                                     release of the Google Cloud
                                     Platform Service Broker
  beta   cloud-storage               Google Cloud Storage plan for
                                     the Beta release of the Google
                                     Cloud Platform Service Broker
```

Now we must build an image of our application to deploy (assumes Habitat is installed/configured):

```
$ git clone https://github.com/skpaterson/table-setting
$ cd table-setting
$ hab studio enter
[STUDIO] build
[STUDIO] hab pkg export docker $(ls -1t results/*.hart | head -1)
```

Upload your built image to [Google Container Registry](https://cloud.google.com/container-registry/):

```bash
# assumes docker and gcloud are installed locally, your repo URL will depend on your project name
$ gcloud auth configure-docker
$ docker tag habskp/table-setting:latest eu.gcr.io/spaterson-project/table-setting:latest
$ docker push eu.gcr.io/spaterson-project/table-setting:latest
```

Now we can provision the Cloud SQL database and generate a manifest for our application:

```
$ export APP_IMAGE_NAME=<YOUR APP IMAGE NAME e.g. "eu.gcr.io/spaterson-project/table-setting:latest">
# from the root of this repository (gcp-kube-habitat)
$ ./applications/setup-mysql-svcat.sh
```

After some time, the MySQL DB will be available, along with a manifest in the applications directory.  This is what will be used to run on our cluster.  Deploy the application via:

```bash
$ kubectl create -f applications/sample-deployment.yml
deployment "table-setting" created
service "cloudsql-user-service" created
```

As in the previous example, we wait until an external IP address is assigned:
 
```bash
$ kubectl get service cloudsql-user-service --namespace cloud-mysql
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
cloudsql-user-service   LoadBalancer   10.51.247.227   35.123.84.130   80:30712/TCP   2m
```

Navigate to the external IP address  and you should see the Table Setting UI!

To clean up, run:

```bash
$ kubectl delete -f applications/sample-deployment.yml
```


## Clean everything up 

The below command cleans up the resources created with terraform.  There is no protection for anything running within the cluster, processes will be stopped.

```
$ bundle exec rake test:cleanup_integration_tests
```

## FAQ

### Quota increase for zone

The terraform templates could generate sufficient resources to require an increase to default in_use IP addresses for a project or zone.

To find this setting, log in to the GCP web interface and go to **IAM and admin->Quotas** and look for "Compute Engine API In-use IP addresses" for the project/zone.  From here you can "Edit quotas" to request more.
```
Changed Quota:
+----------------------+------------------+
| Region: europe-west2 | IN_USE_ADDRESSES |
+----------------------+------------------+
|       Changes        |     8 -> 64      |
+----------------------+------------------+
```

## License
```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
