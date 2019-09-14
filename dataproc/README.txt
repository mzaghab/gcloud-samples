# create project : 
export PROJECT_ID=cloudera-director-2019
gcloud projects create $PROJECT_ID

# config
gcloud config set project $PROJECT_ID
gcloud config set account vpodg1-prd-pf-phenix-sa@v$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts create phenix-prd-caas-gke --display-name "phenix-prd-caas-gke" --project $PROJECT_ID

# activate service eccount
gcloud auth activate-service-account --key-file dataproc-proto-247914-c946ed7dea8c.json

#  activate API
gcloud services enable dataproc.googleapis.com --project $PROJECT_ID


- auto scaling dataproc cluster : 
gcloud beta dataproc clusters create cluster-name --properties "\
dataproc:alpha.autoscaling.enabled=true,\
dataproc:alpha.autoscaling.primary.max_workers=100,\
dataproc:alpha.autoscaling.secondary.max_workers=100,\
dataproc:alpha.autoscaling.cooldown_period=2m,\
dataproc:alpha.autoscaling.scale_up.factor=0.05,\
dataproc:alpha.autoscaling.graceful_decommission_timeout=0m"


gcloud beta dataproc clusters create proto-cluster-name --enable-component-gateway --bucket dataproc-proto --region europe-west1 --subnet default --no-address --zone europe-west1-b --num-masters 3 --master-machine-type n1-standard-2 --master-boot-disk-size 500 --num-workers 2 --worker-machine-type n1-standard-2 --worker-boot-disk-size 500 --image-version 1.3-debian9 --project dataproc-proto-247914

# default 
gcloud dataproc clusters create example-cluster
gcloud dataproc clusters create example-cluster --subnet default --zone us-central1-a --master-machine-type n1-standard-4 --master-boot-disk-size 500 --num-workers 2 --worker-machine-type n1-standard-4 --worker-boot-disk-size 500 --image-version 1.3-deb9 --project qwiklabs-gcp-6929b50327ad3978



# Submit job :
gcloud dataproc jobs submit spark --cluster example-cluster \
  --class org.apache.spark.examples.SparkPi \
  --jars file:///usr/lib/spark/examples/jars/spark-examples.jar -- 1000

# To change the number of workers in the cluster to four, run the following command:
gcloud dataproc clusters update example-cluster --num-workers 4
