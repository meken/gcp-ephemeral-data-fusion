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


data "google_compute_network" "vpc_sample" {
    name = var.network_name
}

data "google_compute_subnetwork" "subnet" {
    name = "sub-default"
    region = var.region
}

data "google_service_account" "service_account" {
    account_id = "sac-dataproc"
}

resource "google_data_fusion_instance" "datafusion" {
    name = var.cdf_name
    region = var.region
    type = "DEVELOPER"
    enable_stackdriver_logging = true
    enable_stackdriver_monitoring = true
    private_instance = false
    network_config {
        network = data.google_compute_network.vpc_sample.name
        ip_allocation = var.ip_range
    }
    dataproc_service_account = data.google_service_account.service_account.email
}

module "pipelines" {
    source = "./cdap"
    depends_on = [
      google_data_fusion_instance.datafusion
    ]
}

output "datafusion_instance_id" {
    value = google_data_fusion_instance.datafusion.name
}