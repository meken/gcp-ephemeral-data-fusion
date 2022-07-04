terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "4.27.0"
        }
        cdap = {
            source = "GoogleCloudPlatform/cdap"
            version = "0.9.0"
        }
    }
}

provider "google" {
    project = var.project
}


data "google_client_config" "current" { }

provider "cdap" {
    host  = "${google_data_fusion_instance.datafusion.service_endpoint}/api/"
    token = data.google_client_config.current.access_token
}

locals {
    suffix = "sample-ku65"
    region = "europe-west4"
    zone = "europe-west4-a"
}


data "google_compute_network" "vpc_sample" {
    name = "vpc-${local.suffix}"
}

data "google_compute_subnetwork" "subnet" {
    name = "sub-default"
    region = local.region
}

data "google_service_account" "service_account" {
    account_id = "sac-dataproc"
}

resource "google_data_fusion_instance" "datafusion" {
    name = "cdf-${local.suffix}"
    region = local.region
    type = "DEVELOPER"
    enable_stackdriver_logging = true
    enable_stackdriver_monitoring = true
    private_instance = false
    network_config {
        network = data.google_compute_network.vpc_sample.name
        ip_allocation = "10.128.0.0/22"
    }
    dataproc_service_account = data.google_service_account.service_account.email
}

module "pipelines" {
    source = "./cdap"
    depends_on = [
      google_data_fusion_instance.datafusion
    ]
}