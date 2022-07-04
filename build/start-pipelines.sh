#!/bin/bash

export AUTH_TOKEN=$(gcloud auth print-access-token)
export INSTANCE_ID=cdf-sample-ku65
export CDAP_ENDPOINT=$(gcloud beta data-fusion instances describe \
   --location=europe-west4 \
   --format="value(apiEndpoint)" \
    ${INSTANCE_ID})

SECRET_NAMES=`gcloud secrets list --format="value(name)"`
for SECRET in $SECRET_NAMES; do
    SECRET_VALUE=`gcloud secrets versions access latest --secret=$SECRET`
    BODY=$(jq -n --arg data "$SECRET_VALUE" '$ARGS.named')
    curl -X PUT -H "Authorization: Bearer ${AUTH_TOKEN}" -d "$BODY" \
       "${CDAP_ENDPOINT}/v3/namespaces/default/securekeys/${SECRET}"
done

# list pipelines and do for each pipeline
export PIPELINES=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
    "${CDAP_ENDPOINT}/v3/namespaces/default/apps?artifactName=cdap-data-pipeline" | jq -r '.[] | .name'`

for PIPELINE in $PIPELINES; do
    curl -X POST -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "${CDAP_ENDPOINT}/v3/namespaces/default/apps/${PIPELINE}/workflows/DataPipelineWorkflow/start"
done
