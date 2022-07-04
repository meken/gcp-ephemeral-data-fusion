variable "project" {
    type = string
    description = "The GCP project name"
}

variable "network_name" {
    type = string
    description = "The name of the VPC network to use"
}

variable "subnet_name" {
    type = string
    description = "The name of the VPC subnet"
}

variable "cdf_name" {
    type = string
    description = "The name of the Data Fusion instance to be created"
}

variable "ip_range" {
    type = string
    description = "The IP range for the Data Fusion instance"
}

variable "region" {
    type = string
    description = "The default region for the resources"
}