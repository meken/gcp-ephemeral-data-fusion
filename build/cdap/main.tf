# auto-generated
terraform {
    required_providers {
        cdap = {
            source = "GoogleCloudPlatform/cdap"
            version = "0.9.0"
        }
    }
}

resource "cdap_application" "pipeline001" {
    name = "example_pipeline_v2"
    spec = file("${path.module}/../../pipelines/example_pipeline_v2-cdap-data-pipeline.json")
}
