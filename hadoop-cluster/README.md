# gcloud-samples
Common commands : 
Check active gcloud account : 

    gcloud auth list

Every command requires a project ID. Set a default project ID, zone and region. so you do not need to provide them every time.

    gcloud config set project xxxxxxx
    gcloud config set compute/region europe-west1
    gcloud config set compute/zone europe-west1-b

## Overview

This is a [Google Cloud Deployment
Manager](https://cloud.google.com/deployment-manager/overview) template which
deploys a single VM with a data disk. This is the most basic example of a
template, and takes only the VM zone as a parameter.

## Deploy the template

Use `cluster.yaml` to deploy this example template. Before deploying, edit the file
and specify the zone in which to create the VM instance by replacing the ZONE_TO_RUN.

When ready, deploy with the following command:

    gcloud deployment-manager deployments create my-cluster --config cluster.yaml

Check your new deployment

    gcloud deployment-manager deployments describe my-cluster

Clean up

    gcloud deployment-manager deployments delete my-cluster