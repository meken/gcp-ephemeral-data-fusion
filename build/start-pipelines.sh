#!/bin/bash

CDAP_ENDPOINT=$1
AUTH_TOKEN=$(gcloud auth print-access-token)

SECRET_NAMES=`gcloud secrets list --format="value(name)"`
for SECRET in $SECRET_NAMES; do
    SECRET_VALUE=`gcloud secrets versions access latest --secret=$SECRET`
    BODY=$(jq -n --arg data "$SECRET_VALUE" '$ARGS.named')
    curl -s -X PUT -H "Authorization: Bearer ${AUTH_TOKEN}" -d "$BODY" \
       "${CDAP_ENDPOINT}/v3/namespaces/default/securekeys/${SECRET}"
done

# list pipelines and start each pipeline
PIPELINES=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
    "${CDAP_ENDPOINT}/v3/namespaces/default/apps?artifactName=cdap-data-pipeline" | jq -r '.[] | .name'`

for PIPELINE in $PIPELINES; do
    curl -s -X POST -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "${CDAP_ENDPOINT}/v3/namespaces/default/apps/${PIPELINE}/workflows/DataPipelineWorkflow/start"
done
