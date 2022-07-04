# Running an ephemeral Data Fusion instance
[Cloud Data Fusion](https://cloud.google.com/data-fusion) is a fully managed, code-free data integration service that helps users efficiently build and manage ETL/ELT data pipelines. However, for organizations that have multiple environments (DEV/TEST/ACC/PROD) and different isolated teams it can become costly to host multiple Data Fusion instances 24/7. This repository illustrates an approach where ephemeral Data Fusion instances are created only when the data pipelines need to run and destroyed after the pipelines finish.

Build status: [![Pipelines](https://github.com/meken/gcp-ephemeral-data-fusion/actions/workflows/build.yaml/badge.svg?branch=main&event=workflow_dispatch)](https://github.com/meken/gcp-ephemeral-data-fusion/actions/workflows/build.yaml) 

## Prerequisites
We'll assume that the required services Cloud Data Fusion and Secret Manager are turned on. In addition, the networking needs to be set up properly (at least having a subnet in the region which allows internal communication).

There's also a few service accounts that need to be configured. 
- The build service account (used by the build agent) to create the Data Fusion instance, import the pipelines and run them. This needs at least the following roles:
    - Cloud Data Fusion Admin
    - Compute Network Reader (to resolve networking details)
    - Service Account User (to set up the Dataproc service account)
    - Secret Manager Viewer and Secret Manager Secret Accessor (in order to set up the secure store for Data Fusion, this is specific to our approach)
- The Dataproc service account for Data Fusion (the Data Fusion Service Account, which is created when the service is enabled,  needs to have the Service Account User role on this service account as described [here](https://cloud.google.com/data-fusion/docs/how-to/granting-service-account-permission))
    - Cloud Data Fusion Runner
    - Dataproc Worker
- And probably additional service accounts to access resources such as BQ, GCS (alternative is to give these roles to the Dataproc service account for Data Fusion)

## Solution
Data pipeline developers can use an ephemeral (and possibly cheap _DEVELOPER_ edition) Data Fusion instance for development. When they are finished with development, they'd need to export the pipeline(s) and commit to a Git (development) branch. Once the changes are pushed, a CI/CD pipeline will create a new ephemeral Data Fusion instance in the project for the environment (dev/test) and will import the pipelines, and trigger them. If the build is successful (depends on pipeline success) the branch can be promoted to the following environment (staging), if that's also successful, the branch can be merged to trunk (this could be through a pull request). The instance running in the production environment should either be _BASIC_ or _ENTERPRISE_ edition to be more reliable and handle possibly multiple pipelines running at the same time.

> Note that the build will be running until all the pipelines are finished. This might require increasing the timeouts for the build agent. If this is not feasible or desirable, the build might trigger a new [Cloud Function](https://cloud.google.com/functions) that could periodically poll the status of all pipelines and destroy the Data Fusion instance (and stop itself) when the pipelines are completed. Keep in mind that the example build configuration provided in this repository uses a simplistic approach for the Terraform backend storage (a local one), changing the approach would require using a different (shared and persistent) backend.

### Scheduling
The CI/CD pipeline configuration for the trunk should be a scheduled build (not a push triggered one) as that will be determining the frequency and timing of when the data pipelines should be running in production.

> Note that this assumes that all pipelines for an instance/environment will be running in parallel and started at the same time. In other words, the scheduling capabilities of the Data Fusion instance won't be used.

If the scheduling capabilities of the build system is not sufficient, [Cloud Scheduler](https://cloud.google.com/scheduler) could be utilized for triggering the build.

### Connection parameters
There are different ways of parametrizing the connection parameters for each environment. Easiest approach would be to provide the Dataproc service account for Data Fusion the necessary roles to access data sources. However, this is quite generic and would only work with data sources that can work with GCP IAM. It's also possible the use Connection Manager in Data Fusion, but that only supports a limited number of data sources for now. We could use macros and provide those as runtime arguments, but that would show the values in clear text in logs, which is not desirable.

Our recommended approach is to use `${secure()}` macros to provide connection details per environment. This requires every instances to be seeded with the right values before the pipelines are started. In order to store the values in a persistent and secure way (as the Data Fusion instances are ephemeral) we suggest [Secret Manager](https://cloud.google.com/secret-manager). In short, when the Data Fusion instance is created, all the secrets from Secret Manager are automatically copied into the secure store of that instance by the build agent.

### Logging
Since Data Fusion instances are ephemeral, the meta data and logs would be lost after the instance is destroyed. In order to keep (some of) this information, our recommendation is to enable Stackdriver logging and monitoring. This makes the logs more persistent by storing the data in Cloud Logging, but it requires some custom querying and filtering to get the relevant logs.

## Summary
This repository illustrates how to use ephemeral Data Fusion instances for better cost management taking into account how to deal with different environments and their configurations. All of that is automated and captured in a build configuration for Github Actions workflow. 
