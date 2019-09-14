terraform {
 backend "gcs" {
   bucket = "${PROJECT_ID}"
   prefix  = "terraform/state"
 }
}
