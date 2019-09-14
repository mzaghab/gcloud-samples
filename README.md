# gcloud-samples

## Prerequisites

Your system needs the `gcloud` cli, as well as `terraform`:

```bash
brew update
brew install terraform
```

## Notes

You will need a key file for your [service account](https://cloud.google.com/iam/docs/service-accounts)
to allow terraform to deploy resources. If you don't have one, you can create a service account and a key for it:

```bash
export PROJECT_ID="YYYYYYYYY"
export ACCOUNT_NAME="XXXXXXXXX"
gcloud iam service-accounts create ${ACCOUNT_NAME} --display-name "My Service Account"
gcloud iam service-accounts keys create "${ACCOUNT_NAME}-key.json" --iam-account "${ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member 'serviceAccount:${ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com' --role 'roles/owner'
```
### Var File

Copy the stub content below into a file called `terraform.tfvars` and put it in the root of this project.
These vars will be used when you run `terraform  apply`.
You should fill in the stub values with the correct content.

```hcl
env_name         = "some-environment-name"
project          = "your-gcp-project"
region           = "us-central1"
zones            = ["us-central1-a", "us-central1-b", "us-central1-c"]
dns_suffix       = "gcp.some-project.cf-app.com"
opsman_image_url = "https://storage.googleapis.com/ops-manager-us/pcf-gcp-2.0-build.264.tar.gz"

buckets_location = "US"

service_account_key = <<SERVICE_ACCOUNT_KEY
{
  "type": "service_account",
  "project_id": "your-gcp-project",
  "private_key_id": "another-gcp-private-key",
  "private_key": "-----BEGIN PRIVATE KEY-----another gcp private key-----END PRIVATE KEY-----\n",
  "client_email": "something@example.com",
  "client_id": "11111111111111",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/"
}
SERVICE_ACCOUNT_KEY
```
===================================================
see https://github.com/steinim/gcp-terraform-workshop/blob/master/terraform/test/main.tf
https://github.com/terraform-google-modules

## Export the following vars
```bash
export PROJECT_ID="YYYYYYYYY"
export ACCOUNT_NAME="XXXXXXXXX"
export REGION="yyyyy"
gcloud iam service-accounts create ${ACCOUNT_NAME} --display-name "My Service Account"
gcloud iam service-accounts keys create "${ACCOUNT_NAME}-key.json" --iam-account "${ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member 'serviceAccount:${ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com' --role 'roles/owner'
```

## Create the service account

Create the service account in the Terraform admin project and download the JSON credentials:
```
gcloud iam service-accounts create ${SERVICE_ACCOUNT} --display-name "${SERVICE_ACCOUNT}" --project ${PROJECT_ID}

gcloud iam service-accounts keys create ${SERVICE_ACCOUNT}-key.json --iam-account ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com --role roles/viewer

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com --role roles/storage.admin
```

## Enable apis

Any actions that Terraform performs require that the API be enabled to do so. In this guide, Terraform requires the following:
```
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

## Set up remote state in Cloud Storage

Create the remote backend bucket in Cloud Storage and the backend.tf file for storage of the terraform.tfstate file:

```

cd terraform

gsutil mb -l ${REGION} -p ${PROJECT_ID} gs://${PROJECT_ID}

cat > backend.tf <<EOF
terraform {
 backend "gcs" {
   bucket = "${PROJECT_ID}"
   prefix  = "terraform/state/test"
 }
}
EOF
```

## Initialize the backend:
`terraform init` and check that everything works with `terraform plan`

# Task 2: Create a new project

## Objectives
* Organize your code into environments and modules
* Usage of variables and outputs
* Use Terraform to provision a new project

## Create your first module: `project`

Terraform resources :
  * [provider "google"](https://www.terraform.io/docs/providers/google/index.html)
  * [resource "random_id"](https://www.terraform.io/docs/providers/random/r/id.html): Project IDs must be unique. Generate a random one prefixed by the desired project ID.
  * [resource "google_project"](https://www.terraform.io/docs/providers/google/r/google_project.html): The new project to create, bound to the desired organization ID and billing account.
  * [resource "google_project_services"](https://www.terraform.io/docs/providers/google/r/google_project_services.html): Services and APIs enabled within the new project.

Terraform resources used:
  * [output "id"](https://www.terraform.io/intro/getting-started/outputs.html): The project ID is randomly generated for uniqueness. Use an output variable to display it after Terraform runs for later reference. The length of the project ID should not exceed 30 characters.
  * [output "name"](https://www.terraform.io/intro/getting-started/outputs.html): The project name.

`vars.tf`:
```
variable "name" {}
variable "region" {}
variable "billing_account" {}
variable "org_id" {}
```

## Initialize once again to download providers used in the module:
`terraform init`

## Always run plan first!
`terraform plan`

## Provision the infrastructure
`terraform apply`

Verify your success in the GCP console 💰

# Networking and bastion host

## Create the network module

```
modules/network/
├── vars.tf
├── main.tf
├── outputs.tf
├── bastion
│   ├── main.tf
│   ├── outputs.tf
│   └── vars.tf
├── subnet
│   ├── main.tf
│   ├── outputs.tf
│   └── vars.tf
```

<p>
<details>
<summary><strong>Subnet module</strong> `modules/network/subnet`</summary>

```
# main.tf
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}"
  project       = "${var.project}"
  region        = "${var.region}"
  network       = "${var.network}"
  ip_cidr_range = "${var.ip_range}"
}

---

# vars.tf
variable "name" {}
variable "project" {}
variable "region" {}
variable "network" {}
variable "ip_range" {}

---

# outputs.tf
output "ip_range" {
  value = "${google_compute_subnetwork.subnet.ip_cidr_range}"
}
output "self_link" {
  value = "${google_compute_subnetwork.subnet.self_link}"
}

```
</details>
</p>

<p>
<details>
<summary><strong>Bastion host module</strong>`modules/network/bastion`</summary>

```
# main.tf
resource "google_compute_instance" "bastion" {
  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, 0)}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    subnetwork = "${var.subnet_name}"

    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  tags = ["bastion"]
}

---

# vars.tf
variable "name" {}
variable "project" {}
variable "zones" { type = "list" }
variable "subnet_name" {}
variable "image" {}
variable "instance_type" {}
variable "user" {}
variable "ssh_key" {}

---

# outputs.tf
output "private_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.address}"
}
output "public_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}"
}
```
</details>
</p>

<p>
<details>
<summary><strong>Network</strong>`modules/network/`</summary>

```
# main.tf
resource "google_compute_network" "network" {
  name    = "${var.name}-network"
  project = "${var.project}"
}

resource "google_compute_firewall" "allow-internal" {
  name    = "${var.name}-allow-internal"
  project = "${var.project}"
  network = "${var.name}-network"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    "${module.management_subnet.ip_range}",
    "${module.webservers_subnet.ip_range}"
  ]
}

resource "google_compute_firewall" "allow-ssh-from-everywhere-to-bastion" {
  name    = "${var.name}-allow-ssh-from-everywhere-to-bastion"
  project = "${var.project}"
  network = "${var.name}-network"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["bastion"]
}

resource "google_compute_firewall" "allow-ssh-from-bastion-to-webservers" {
  name               = "${var.name}-allow-ssh-from-bastion-to-webservers"
  project            = "${var.project}"
  network            = "${var.name}-network"
  direction          = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags        = ["ssh"]
}

resource "google_compute_firewall" "allow-ssh-to-webservers-from-bastion" {
  name          = "${var.name}-allow-ssh-to-private-network-from-bastion"
  project       = "${var.project}"
  network       = "${var.name}-network"
  direction     = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags   = ["bastion"]
}

resource "google_compute_firewall" "allow-http-to-appservers" {
  name          = "${var.name}-allow-http-to-appservers"
  project       = "${var.project}"
  network       = "${var.name}-network"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  source_tags   = ["http"]
}

resource "google_compute_firewall" "allow-db-connect-from-webservers" {
  name               = "${var.name}-allow-db-connect-from-webservers"
  project            = "${var.project}"
  network            = "${var.name}-network"
  direction          = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  destination_ranges = ["0.0.0.0/0"]

  target_tags        = ["db"]
}

module "management_subnet" {
  source   = "./subnet"
  project  = "${var.project}"
  region   = "${var.region}"
  name     = "${var.management_subnet_name}"
  network  = "${google_compute_network.network.self_link}"
  ip_range = "${var.management_subnet_ip_range}"
}

module "webservers_subnet" {
  source   = "./subnet"
  project  = "${var.project}"
  region   = "${var.region}"
  name     = "${var.webservers_subnet_name}"
  network  = "${google_compute_network.network.self_link}"
  ip_range = "${var.webservers_subnet_ip_range}"
}

module "bastion" {
  source        = "./bastion"
  name          = "${var.name}-bastion"
  project       = "${var.project}"
  zones         = "${var.zones}"
  subnet_name   = "${module.management_subnet.self_link}"
  image         = "${var.bastion_image}"
  instance_type = "${var.bastion_instance_type}"
  user          = "${var.user}"
  ssh_key       = "${var.ssh_key}"
}

---

# vars.tf
variable "name" {}
variable "project" {}
variable "region" {}
variable "zones" { type = "list" }
variable "webservers_subnet_name" {}
variable "webservers_subnet_ip_range" {}
variable "management_subnet_name" {}
variable "management_subnet_ip_range" {}
variable "bastion_image" {}
variable "bastion_instance_type" {}
variable "user" {}
variable "ssh_key" {}

---

# outputs.tf
output "name" {
  value = "${google_compute_network.network.name}"
}
output "bastion_public_ip" {
  value = "${module.bastion.public_ip}"
}
output "gateway_ipv4"  {
  value = "${google_compute_network.network.gateway_ipv4}"
}
```
</details>
</p>

<p>
<details>
<summary><strong>Use the subnet module in your main project</strong> `test/`</summary>

```
# main.tf

...

module "network" {
  source                     = "../modules/network"
  name                       = "${module.project.name}"
  project                    = "${module.project.id}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  webservers_subnet_name     = "webservers"
  webservers_subnet_ip_range = "${var.webservers_subnet_ip_range}"
  management_subnet_name     = "management"
  management_subnet_ip_range = "${var.management_subnet_ip_range}"
  bastion_image              = "${var.bastion_image}"
  bastion_instance_type      = "${var.bastion_instance_type}"
  user                       = "${var.user}"
  ssh_key                    = "${var.ssh_key}"
}

---

# vars.tf
...
variable "zones" { default = ["europe-west3-a", "europe-west3-b"] }
variable "webservers_subnet_ip_range" { default = "192.168.1.0/24"}
variable "management_subnet_ip_range" { default = "192.168.100.0/24"}
variable "bastion_image" { default = "centos-7-v20170918" }
variable "bastion_instance_type" { default = "f1-micro" }
variable "user" {}
variable "ssh_key" {}

```

</details>
</p>

## Init, plan, apply!
```
terraform init
terraform plan
terraform apply
```

## SSH into the bastion host 💰
`ssh -i ~/.ssh/<private_key> $USER@$(terraform output --module=network bastion_public_ip)`


# Task 5: Instance templates

`git checkout task5`

## Create the instance template module

```
modules/instance-template
├── main.tf
├── outputs.tf
├── vars.tf
└── scripts/startup.sh
```

<p>
<details>
<summary><strong>Instance template module</strong> `modules/instance-template/`</summary>

```
# main.tf
data "template_file" "init" {
  template = "${file("${path.module}/scripts/startup.sh")}"
  vars {
    db_name     = "${var.db_name}"
    db_user     = "${var.db_user}"
    db_password = "${var.db_password}"
    db_ip       = "${var.db_ip}"
  }
}

resource "google_compute_instance_template" "webserver" {
  name         = "${var.name}-webserver-instance-template"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  region       = "${var.region}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  disk {
    source_image = "${var.image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network            = "${var.network_name}"
    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  metadata_startup_script = "${data.template_file.init.rendered}"

  tags = ["http"]

  labels = {
    environment = "${var.env}"
  }
}

---

# vars.tf

variable "name" {}
variable "project" {}
variable "network_name" {}
variable "image" {}
variable "instance_type" {}
variable "user" {}
variable "ssh_key" {}
variable "env" {}
variable "region" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "db_ip" {}

---

# outputs.tf

output "instance_template" {
  value = "${google_compute_instance_template.webserver.self_link}"
}

---

# scripts/startup.sh
#!/bin/bash

yum install -y nginx java

cat <<'EOF' > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    server {
        listen      80 default_server;
        server_name _;
        location / {
            proxy_pass  http://127.0.0.1:1234;
        }
    }
}
EOF

setsebool -P httpd_can_network_connect true

systemctl enable nginx
systemctl start nginx

cat <<'EOF' > /config.properties
db.user=${db_user}
db.password=${db_password}
db.name=${db_name}
db.ip=${db_ip}
EOF

curl -o app.jar https://morisbak.net/files/helloworld-java-app.jar

java -jar app.jar > /dev/null 2>&1 &

```

</details>
</p>

<p>
<details>
<summary><strong>Use the instance template module in your main project</strong> `test/`</summary>

```
# main.tf

...

module "instance-template" {
  source        = "../modules/instance-template"
  name          = "${module.project.name}"
  env           = "${var.env}"
  project       = "${module.project.id}"
  region        = "${var.region}"
  network_name  = "${module.network.name}"
  image         = "${var.app_image}"
  instance_type = "${var.app_instance_type}"
  user          = "${var.user}"
  ssh_key       = "${var.ssh_key}"
  db_name       = "${module.project.name}"
  db_user       = "hello"
  db_password   = "hello"
  db_ip         = "${module.mysql-db.instance_address}"
}

---

# vars.tf

...

variable "appserver_count" { default = 2 }
variable "app_image" { default = "centos-7-v20170918" }
variable "app_instance_type" { default = "f1-micro" }

```

</details>
</p>

## Init, plan, apply!
```
terraform init
terraform plan
terraform apply
```

## Check that your instance template is created in the console 💰

Browse to the public ip's of the webservers.

# Task 6: Auto scaling and load balancing

`git checkout task6`

What you'll need 😰:

  * google_compute_global_forwarding_rule
  * google_compute_target_http_proxy
  * google_compute_url_map
  * google_compute_backend_service
  * google_compute_http_health_check
  * google_compute_instance_group_manager
  * google_compute_target_pool
  * google_compute_instance_group
  * google_compute_autoscaler

## Create the lb module

```
modules/lb
├── main.tf
└── vars.tf
```

<p>
<details>
<summary><strong>Load balancer module</strong> `modules/lb/`</summary>

```

# main.tf
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "${var.name}-global-forwarding-rule"
  project    = "${var.project}"
  target     = "${google_compute_target_http_proxy.target_http_proxy.self_link}"
  port_range = "80"
}

resource "google_compute_target_http_proxy" "target_http_proxy" {
  name        = "${var.name}-proxy"
  project     = "${var.project}"
  url_map     = "${google_compute_url_map.url_map.self_link}"
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.name}-url-map"
  project         = "${var.project}"
  default_service = "${google_compute_backend_service.backend_service.self_link}"
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "${var.name}-backend-service"
  project               = "${var.project}"
  port_name             = "http"
  protocol              = "HTTP"
  backend {
    group                 = "${element(google_compute_instance_group_manager.webservers.*.instance_group, 0)}"
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }

  backend {
    group                 = "${element(google_compute_instance_group_manager.webservers.*.instance_group, 1)}"
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }

  health_checks = ["${google_compute_http_health_check.healthcheck.self_link}"]
}

resource "google_compute_http_health_check" "healthcheck" {
  name         = "${var.name}-healthcheck"
  project      = "${var.project}"
  port         = 80
  request_path = "/"
}

resource "google_compute_instance_group_manager" "webservers" {
  name               = "${var.name}-instance-group-manager-${count.index}"
  project            = "${var.project}"
  instance_template  = "${var.instance_template}"
  base_instance_name = "${var.name}-webserver-instance"
  count              = "${var.count}"
  zone               = "${element(var.zones, count.index)}"
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name    = "${var.name}-scaler-${count.index}"
  project = "${var.project}"
  count   = "${var.count}"
  zone    = "${element(var.zones, count.index)}"
  target  = "${element(google_compute_instance_group_manager.webservers.*.self_link, count.index)}"

  autoscaling_policy = {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 90

    cpu_utilization {
      target = 0.8
    }
  }
}

---

# vars.tf

variable "name" {}
variable "project" {}
variable "region" {}
variable "count" {}
variable "instance_template" {}
variable "zones" { type = "list" }

```
</details>
</p>

<p>
<details>
<summary><strong>Use the load balancer module in your main project</strong> `test/`</summary>

```

# main.tf

...

module "lb" {
  source            = "../modules/lb"
  name              = "${module.project.name}"
  project           = "${module.project.id}"
  region            = "${var.region}"
  count             = "${var.appserver_count}"
  instance_template = "${module.instance-template.instance_template}"
  zones             = "${var.zones}"
}

```

</details>
</p>

## Init, plan, apply!
```
terraform init
terraform plan
terraform apply
```

## SSH into a webserver in the private network using the bastion host as a jump server 💰
```
ssh -i ~/.ssh/id_rsa -J $USER@$(terraform output --module=network bastion_public_ip) $USER@<webserver-private-ip> -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
```

## Browse to the public ip of the load balancer 💰

💰💰💰

# Cleaning up

First, destroy the resources created by Terraform:
`terraform destroy --force`

Finally, delete the Terraform Admin project and all of its resources:
`gcloud projects delete ${TF_ADMIN}`

