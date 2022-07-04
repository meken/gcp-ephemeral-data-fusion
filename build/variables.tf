variable "project" {
    type = string
    description = "The GCP project name"
    default = "meken-data-fusion-prod"
}

variable "network_name" {
    type = string
    description = "The name of the VPC network to use"
    default = "vpc-sample-n4ql"
}

variable "cdf_name" {
    type = string
    description = "The name of the Data Fusion instance to be created"
    default = "cdf-sample-n4ql"
}

variable "ip_range" {
    type = string
    description = "The IP range for the Data Fusion instance"
    default = "10.128.0.0/22"
}

variable "region" {
    type = string
    description = "The default region for the resources"
    default = "europe-west4"
}