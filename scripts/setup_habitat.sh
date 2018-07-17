#!/bin/sh

set -x

# this assumes setup_helm.sh has been run
NAME="gke-demo"
VERSION="0.7.1"

helm repo add habitat https://habitat-sh.github.io/habitat-operator/helm/charts/stable/
helm repo update
helm install --name ${NAME} habitat/habitat-operator --version ${VERSION}
