#!/bin/bash

CDAP_ENDPOINT=$1
AUTH_TOKEN=$(gcloud auth print-access-token)

# list pipelines and start each pipeline
PIPELINES=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
    "${CDAP_ENDPOINT}/v3/namespaces/default/apps?artifactName=cdap-data-pipeline" | jq -r '.[] | .name'`

for PIPELINE in $PIPELINES; do
    curl -s -X POST -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "${CDAP_ENDPOINT}/v3/namespaces/default/apps/${PIPELINE}/workflows/DataPipelineWorkflow/start"
done
